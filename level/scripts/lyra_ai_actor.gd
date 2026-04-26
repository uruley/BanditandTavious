extends CharacterBody3D

enum State {
	IDLE,
	MOVE_TO_TARGET,
	INTERACT,
	REPLAN,
}

const GRAVITY := 18.0
const CAPSULE_HEIGHT := 1.8
const CAPSULE_RADIUS := 0.4
const IDLE_TIMEOUT_SEC := 4.0
const NAV_AGENT_NAME := "NavigationAgent3D"
const WEAPON_MASTER_SCENE := preload("res://level/scenes/weapons/WeaponMaster.tscn")

@export var move_speed: float = 3.2
@export var decision_interval: float = 1.0
@export var interact_distance: float = 1.25
@export var explore_distance: float = 2.5
@export var build_distance: float = 4.5
@export var interact_duration: float = 1.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var hunger_rate: float = 2.0
@export var thirst_rate: float = 3.0
@export var combat_range: float = 10.25
@export var combat_seek_distance: float = 26.0
@export var body_color: Color = Color(0.9, 0.8, 0.25, 1.0)
@export_enum("forager", "hauler", "scout") var role: String = "forager"
@export var wants_weapon: bool = true

var hunger: float = 35.0
var thirst: float = 45.0
var resource_count: int = 0
var route_visit_count: int = 0
var current_goal: String = ""
var current_target: Node3D
var state: int = State.IDLE
var decision_timer: float = 0.0
var interact_timer: float = 0.0
var stuck_seconds: float = 0.0
var idle_seconds: float = 0.0
var _last_position: Vector3
var _last_nav_target: Vector3 = Vector3.INF
var _debug_label: Label3D
var _target_cooldowns: Dictionary = {}
var _weapon_inventory: WeaponInventoryComponent
var _memory_store: Node
var _remembered_spawn_count: int = 0
var _remembered_last_goal: String = ""
var _goal_sequence_id: int = 0
var _current_goal_run_id: int = 0
var _goal_lifecycle_active: bool = false
var _last_lifecycle_goal: String = ""
var _last_lifecycle_result: String = ""
var _last_lifecycle_reason: String = ""
var _last_lifecycle_id: int = 0
var _explore_route := [
	"WP_CentralMarket",
	"WP_EastOuter",
	"WP_NorthEast",
	"WP_NorthCrossing",
	"WP_CentralMarket",
	"WP_SpawnLane",
]
var _explore_route_index: int = 0

@onready var task_board: Node = _find_first_group_node("lyra_ai_task_board")
@onready var metrics: Node = _find_first_group_node("lyra_ai_metrics")
@onready var navigation_agent: NavigationAgent3D = _ensure_navigation_agent()


func _ready() -> void:
	add_to_group("lyra_ai_actor")
	_last_position = global_position
	_configure_explore_route()
	_configure_capsule()
	_ensure_weapon_inventory()
	_restore_memory()
	_log_decision("spawn", {}, 0.0, "actor_ready")


func _physics_process(delta: float) -> void:
	hunger = clampf(hunger + hunger_rate * delta, 0.0, max_hunger)
	thirst = clampf(thirst + thirst_rate * delta, 0.0, max_thirst)
	decision_timer -= delta
	velocity.y -= GRAVITY * delta
	_update_debug_label()

	match state:
		State.IDLE:
			if decision_timer <= 0.0:
				_select_goal()
		State.MOVE_TO_TARGET:
			_move_to_target(delta)
		State.INTERACT:
			_interact(delta)
		State.REPLAN:
			_release_target()
			state = State.IDLE
			decision_timer = 0.15

	move_and_slide()
	_track_stuck(delta)
	_track_idle(delta)


func _configure_capsule() -> void:
	collision_layer = 4
	collision_mask = 1

	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var capsule := CapsuleShape3D.new()
	capsule.height = CAPSULE_HEIGHT
	capsule.radius = CAPSULE_RADIUS
	collision.shape = capsule
	collision.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var body_mesh := get_node_or_null("BodyMesh") as MeshInstance3D
	if body_mesh == null:
		body_mesh = MeshInstance3D.new()
		body_mesh.name = "BodyMesh"
		add_child(body_mesh)
	var mesh := CapsuleMesh.new()
	mesh.height = CAPSULE_HEIGHT
	mesh.radius = CAPSULE_RADIUS
	body_mesh.mesh = mesh
	body_mesh.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var material := StandardMaterial3D.new()
	material.albedo_color = body_color
	body_mesh.material_override = material

	_debug_label = get_node_or_null("Label3D") as Label3D
	if _debug_label == null:
		_debug_label = Label3D.new()
		_debug_label.name = "Label3D"
		_debug_label.position = Vector3(0.0, 2.35, 0.0)
		_debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_debug_label.no_depth_test = true
		add_child(_debug_label)
	_update_debug_label()


func _select_goal() -> void:
	var scores := {
		"food": clampf(hunger / max_hunger, 0.0, 1.0),
		"water": clampf(thirst / max_thirst, 0.0, 1.0),
		"resource": clampf(0.28 + float(max(0, 4 - resource_count)) * 0.1, 0.0, 1.0),
		"build": _build_score(),
		"weapon": _weapon_score(),
		"combat": _combat_score(),
		"explore": _explore_score(),
	}
	_apply_role_bias(scores)
	var ranked_goals := scores.keys()
	ranked_goals.sort_custom(func(a, b): return float(scores[a]) > float(scores[b]))

	current_goal = ""
	current_target = null
	var selected_score := 0.0
	for goal in ranked_goals:
		current_goal = str(goal)
		selected_score = float(scores[current_goal])
		current_target = task_board.call("find_and_reserve", current_goal, self, _target_selection_mode(), _active_target_cooldowns()) if task_board else null
		if current_target != null:
			break
		_log({
			"type": "reservation",
			"actor": name,
			"goal": current_goal,
			"target": "",
			"result": "failure",
			"reason": "goal_targets_reserved",
		})

	_log_decision(current_goal, scores, selected_score, "utility_available")

	if current_goal == "" or current_target == null:
		_log_goal_selection_failed(scores, selected_score, "no_available_target")
		_log_reservation("failure", "no_available_target")
		state = State.IDLE
		decision_timer = decision_interval
		return

	_log_reservation("success", "nearest_available")
	_begin_goal_lifecycle(scores, selected_score, "utility_available")
	_update_navigation_target()
	state = State.MOVE_TO_TARGET
	decision_timer = decision_interval
	idle_seconds = 0.0


func _move_to_target(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		_fail_current_goal("target_invalid")
		state = State.REPLAN
		return

	_update_navigation_target()

	var flat_target := current_target.global_position
	flat_target.y = global_position.y
	var next_position := navigation_agent.get_next_path_position()
	next_position.y = global_position.y
	var offset := next_position - global_position
	var distance := offset.length()
	var target_distance := flat_target.distance_to(global_position)
	var goal_distance := interact_distance
	if current_goal == "combat":
		goal_distance = combat_range
	elif current_goal == "explore":
		goal_distance = explore_distance
	elif current_goal == "build":
		goal_distance = build_distance
	if target_distance <= goal_distance or (navigation_agent.is_navigation_finished() and target_distance <= goal_distance * 1.5):
		velocity.x = 0.0
		velocity.z = 0.0
		interact_timer = interact_duration
		state = State.INTERACT
		return

	if distance < 0.05:
		offset = flat_target - global_position
		distance = offset.length()
		if distance < 0.05:
			return

	var desired_velocity := offset.normalized() * move_speed
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	rotation.y = lerp_angle(rotation.y, atan2(desired_velocity.x, desired_velocity.z), delta * 8.0)


func _interact(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	interact_timer -= delta
	if interact_timer > 0.0:
		return

	var delta_state := {}
	match current_goal:
		"food":
			var before := hunger
			hunger = maxf(0.0, hunger - 55.0)
			delta_state["hunger"] = hunger - before
		"water":
			var before := thirst
			thirst = maxf(0.0, thirst - 65.0)
			delta_state["thirst"] = thirst - before
		"resource":
			resource_count += 1
			delta_state["resource_count"] = 1
		"build":
			if resource_count <= 0 or current_target == null or not current_target.has_method("receive_resource"):
				delta_state["build"] = "failed"
				_log_interaction(delta_state, "failure")
				_fail_current_goal("build_missing_resource_or_receiver", delta_state)
				_cooldown_current_target()
				_release_target()
				state = State.IDLE
				decision_timer = randf_range(0.35, decision_interval)
				return
			var build_result: Dictionary = current_target.call("receive_resource", 1, self)
			var build_status: String = str(build_result.get("build", ""))
			for key in build_result.keys():
				delta_state[key] = build_result[key]
			if build_status != "delivered" and build_status != "completed":
				_log_interaction(delta_state, "failure")
				_fail_current_goal("build_rejected_resource", delta_state)
				_cooldown_current_target()
				_release_target()
				state = State.IDLE
				decision_timer = randf_range(0.35, decision_interval)
				return
			resource_count = max(0, resource_count - 1)
			delta_state["resource_count"] = -1
			_log_build_progress(build_result)
		"weapon":
			var weapon_name := _target_weapon_name(current_target)
			if current_target != null and current_target.has_method("interact") and bool(current_target.call("interact", self)):
				delta_state["weapon"] = weapon_name
			else:
				delta_state["weapon"] = "failed"
				_log_interaction(delta_state, "failure")
				_fail_current_goal("weapon_interact_failed", delta_state)
				_cooldown_current_target()
				_release_target()
				state = State.IDLE
				decision_timer = randf_range(0.35, decision_interval)
				return
		"combat":
			delta_state = _try_fire_at_combat_target(current_target)
			if str(delta_state.get("shot", "")) != "hit":
				_log_interaction(delta_state, "failure")
				_fail_current_goal("combat_shot_failed", delta_state)
				_release_target()
				state = State.IDLE
				decision_timer = randf_range(0.2, decision_interval)
				return
		"explore":
			route_visit_count += 1
			delta_state["route_visit_count"] = route_visit_count
			delta_state["waypoint"] = current_target.name if current_target else ""
			_log_route_visit()
			_cooldown_current_target()
			_advance_explore_route()

	_log_interaction(delta_state)
	_complete_current_goal(delta_state)
	_release_target()
	state = State.IDLE
	decision_timer = randf_range(0.35, decision_interval)


func _track_stuck(delta: float) -> void:
	var moved := global_position.distance_to(_last_position)
	if state == State.MOVE_TO_TARGET and current_target != null and moved < 0.01:
		stuck_seconds += delta
		if stuck_seconds >= 2.0:
			_log_stuck()
			_fail_current_goal("stuck_timeout", {"stuck_seconds": stuck_seconds})
			_cooldown_current_target()
			if current_goal == "explore":
				_advance_explore_route()
			state = State.REPLAN
			stuck_seconds = 0.0
	else:
		stuck_seconds = 0.0
	_last_position = global_position


func _track_idle(delta: float) -> void:
	if state != State.IDLE or current_target != null:
		idle_seconds = 0.0
		return
	idle_seconds += delta
	if idle_seconds < IDLE_TIMEOUT_SEC:
		return
	_log({
		"type": "actor_idle_timeout",
		"actor": name,
		"role": role,
		"goal": current_goal,
		"idle_seconds": idle_seconds,
		"last_goal": _last_lifecycle_goal,
		"last_result": _last_lifecycle_result,
		"last_reason": _last_lifecycle_reason,
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
	})
	idle_seconds = 0.0


func _release_target() -> void:
	if current_target != null and is_instance_valid(current_target):
		_log_goal_event("goal_cleanup", {"reason": "release_target"})
		if _goal_uses_reservation(current_goal):
			_log_goal_event("reservation_released", {"result": "released", "reason": "release_target"})
	if task_board and current_target and is_instance_valid(current_target):
		task_board.call("release", self, current_target)
	current_target = null
	_last_nav_target = Vector3.INF


func _ensure_weapon_inventory() -> void:
	var weapon_master := get_node_or_null("WeaponMaster") as Node3D
	if weapon_master == null:
		weapon_master = WEAPON_MASTER_SCENE.instantiate() as Node3D
		weapon_master.name = "WeaponMaster"
		weapon_master.position = Vector3(0.45, 1.15, 0.15)
		weapon_master.scale = Vector3(0.5, 0.5, 0.5)
		add_child(weapon_master)
	weapon_master.visible = false
	weapon_master.set("weapon_resource", null)

	_weapon_inventory = get_node_or_null("WeaponInventory") as WeaponInventoryComponent
	if _weapon_inventory == null:
		_weapon_inventory = WeaponInventoryComponent.new()
		_weapon_inventory.name = "WeaponInventory"
		_weapon_inventory.weapon_master_path = NodePath("../WeaponMaster")
		add_child(_weapon_inventory)
	else:
		_weapon_inventory.weapon_master_path = NodePath("../WeaponMaster")


func _ensure_navigation_agent() -> NavigationAgent3D:
	var agent := get_node_or_null(NAV_AGENT_NAME) as NavigationAgent3D
	if agent != null:
		return agent
	agent = NavigationAgent3D.new()
	agent.name = NAV_AGENT_NAME
	agent.radius = CAPSULE_RADIUS
	agent.height = CAPSULE_HEIGHT
	agent.path_desired_distance = 0.35
	agent.target_desired_distance = interact_distance
	agent.avoidance_enabled = false
	add_child(agent)
	return agent


func _update_navigation_target() -> void:
	if current_target == null or navigation_agent == null:
		return
	var target_position := current_target.global_position
	if target_position.distance_to(_last_nav_target) < 0.05:
		return
	navigation_agent.target_position = target_position
	_last_nav_target = target_position


func _update_debug_label() -> void:
	if _debug_label == null:
		return
	var target_name: String = current_target.name if current_target else "-"
	_debug_label.text = "%s\n%s -> %s\nH %.0f T %.0f R %d W %s M %d" % [
		name,
		current_goal if current_goal != "" else "idle",
		target_name,
		hunger,
		thirst,
		resource_count,
		"yes" if _has_weapon() else "no",
		_remembered_spawn_count,
	]


func _log_decision(goal: String, scores: Dictionary, score: float, reason: String) -> void:
	_log({
		"type": "decision",
		"actor": name,
		"role": role,
		"goal": goal,
		"score": score,
		"scores": scores,
		"target": current_target.name if current_target else "",
		"target_distance": global_position.distance_to(current_target.global_position) if current_target else -1.0,
		"reason": reason,
	})


func _log_reservation(result: String, reason: String) -> void:
	_log({
		"type": "reservation",
		"actor": name,
		"goal": current_goal,
		"target": current_target.name if current_target else "",
		"target_distance": global_position.distance_to(current_target.global_position) if current_target else -1.0,
		"result": result,
		"reason": reason,
	})


func _log_interaction(delta_state: Dictionary, result: String = "success") -> void:
	_log({
		"type": "interaction_complete",
		"actor": name,
		"role": role,
		"goal": current_goal,
		"target": current_target.name if current_target else "",
		"duration_sec": interact_duration,
		"result": result,
		"delta": delta_state,
	})


func _begin_goal_lifecycle(scores: Dictionary, score: float, reason: String) -> void:
	_goal_sequence_id += 1
	_current_goal_run_id = _goal_sequence_id
	_goal_lifecycle_active = true
	if _last_lifecycle_goal != "":
		_log_goal_event("next_goal_selected", {
			"previous_goal_id": _last_lifecycle_id,
			"previous_goal": _last_lifecycle_goal,
			"previous_result": _last_lifecycle_result,
			"previous_reason": _last_lifecycle_reason,
		})
	_log_goal_event("goal_selected", {
		"score": score,
		"scores": scores,
		"reason": reason,
	})
	_log_goal_event("goal_started", {
		"state": "move_to_target",
		"reason": "target_available",
	})


func _log_goal_selection_failed(scores: Dictionary, score: float, reason: String) -> void:
	_goal_sequence_id += 1
	_current_goal_run_id = _goal_sequence_id
	_goal_lifecycle_active = false
	_log_goal_event("goal_selected", {
		"score": score,
		"scores": scores,
		"reason": reason,
	})
	_log_goal_event("goal_failed", {
		"result": "failure",
		"reason": reason,
	})
	_remember_goal_result("failure", reason)


func _complete_current_goal(delta_state: Dictionary) -> void:
	if not _goal_lifecycle_active:
		return
	_log_goal_event("goal_completed", {
		"result": "success",
		"reason": "interaction_complete",
		"delta": delta_state,
	})
	_remember_goal_result("success", "interaction_complete")


func _fail_current_goal(reason: String, delta_state: Dictionary = {}) -> void:
	if not _goal_lifecycle_active:
		return
	_log_goal_event("goal_failed", {
		"result": "failure",
		"reason": reason,
		"delta": delta_state,
	})
	_remember_goal_result("failure", reason)


func _remember_goal_result(result: String, reason: String) -> void:
	_goal_lifecycle_active = false
	_last_lifecycle_goal = current_goal
	_last_lifecycle_result = result
	_last_lifecycle_reason = reason
	_last_lifecycle_id = _current_goal_run_id


func _log_goal_event(event_type: String, extra: Dictionary = {}) -> void:
	var target_name := ""
	var target_distance := -1.0
	if current_target != null and is_instance_valid(current_target):
		target_name = current_target.name
		target_distance = global_position.distance_to(current_target.global_position)
	var event := {
		"type": event_type,
		"actor": name,
		"role": role,
		"goal": current_goal,
		"goal_id": _current_goal_run_id,
		"target": target_name,
		"target_distance": target_distance,
		"state": _state_name(state),
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
	}
	for key in extra.keys():
		event[key] = extra[key]
	_log(event)


func _goal_uses_reservation(goal: String) -> bool:
	return goal != "combat" and goal != "explore" and goal != "build"


func _state_name(state_id: int) -> String:
	match state_id:
		State.IDLE:
			return "idle"
		State.MOVE_TO_TARGET:
			return "move_to_target"
		State.INTERACT:
			return "interact"
		State.REPLAN:
			return "replan"
	return "unknown"


func _log_stuck() -> void:
	_log({
		"type": "stuck",
		"actor": name,
		"role": role,
		"goal": current_goal,
		"target": current_target.name if current_target else "",
		"stuck_seconds": stuck_seconds,
		"distance_to_target": global_position.distance_to(current_target.global_position) if current_target else -1.0,
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
	})


func _log(event: Dictionary) -> void:
	if metrics and metrics.has_method("log_event"):
		metrics.call("log_event", event)


func _restore_memory() -> void:
	_memory_store = _find_first_group_node("lyra_ai_memory_store")
	if _memory_store == null or not _memory_store.has_method("register_actor"):
		return
	var memory := _memory_store.call("register_actor", name, role) as Dictionary
	if memory.is_empty():
		return
	_remembered_spawn_count = int(memory.get("spawn_count", 0))
	_remembered_last_goal = str(memory.get("last_goal", ""))
	_log({
		"type": "ai_memory_restored",
		"actor": name,
		"role": role,
		"remembered_spawn_count": _remembered_spawn_count,
		"remembered_last_goal": _remembered_last_goal,
		"remembered_successful_interactions": int(memory.get("successful_interaction_count", 0)),
		"remembered_weapon_pickups": int(memory.get("weapon_pickup_count", 0)),
	})


func _find_first_group_node(group_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group_name)
	return nodes[0] if not nodes.is_empty() else null


func _apply_role_bias(scores: Dictionary) -> void:
	match role:
		"forager":
			scores["food"] = clampf(float(scores["food"]) + 0.15, 0.0, 1.0)
			scores["water"] = clampf(float(scores["water"]) + 0.15, 0.0, 1.0)
		"hauler":
			scores["resource"] = clampf(float(scores["resource"]) + 0.3, 0.0, 1.0)
			scores["build"] = clampf(float(scores["build"]) + 0.2, 0.0, 1.2)
		"scout":
			scores["resource"] = clampf(float(scores["resource"]) + 0.12, 0.0, 1.0)
			scores["weapon"] = clampf(float(scores["weapon"]) + 0.1, 0.0, 1.0)
			scores["explore"] = float(scores["explore"]) + 0.08


func _target_selection_mode() -> String:
	return "farthest" if role == "scout" else "nearest"


func _active_target_cooldowns() -> Array[String]:
	var now_sec := Time.get_ticks_msec() * 0.001
	var active: Array[String] = []
	for target_name in _target_cooldowns.keys():
		if float(_target_cooldowns[target_name]) > now_sec:
			active.append(str(target_name))
		else:
			_target_cooldowns.erase(target_name)
	return active


func _cooldown_current_target() -> void:
	if current_target == null:
		return
	_target_cooldowns[current_target.name] = Time.get_ticks_msec() * 0.001 + 8.0


func _configure_explore_route() -> void:
	if role != "scout":
		return
	var actor_number := name.get_slice("_", 1).to_int()
	if actor_number > 0 and actor_number % 2 == 0:
		_explore_route = [
			"WP_CentralMarket",
			"WP_SpawnLane",
			"WP_CentralMarket",
			"WP_SpawnLane",
		]


func get_next_explore_waypoint() -> String:
	if _explore_route.is_empty():
		return ""
	return str(_explore_route[_explore_route_index % _explore_route.size()])


func _advance_explore_route() -> void:
	if _explore_route.is_empty():
		return
	_explore_route_index = (_explore_route_index + 1) % _explore_route.size()


func _weapon_score() -> float:
	if not wants_weapon or _has_weapon():
		return 0.05
	return 0.92


func _combat_score() -> float:
	if not _has_weapon() or _available_combat_target_count() <= 0:
		return 0.0
	return 0.86 if role == "scout" else 0.99


func _build_score() -> float:
	if resource_count <= 0 or _available_build_site_count() <= 0:
		return 0.0
	return 0.98 if role == "hauler" else 0.58


func _explore_score() -> float:
	if _available_waypoint_count() <= 0:
		return 0.0
	if role == "scout":
		if not _has_weapon():
			return 0.48
		return 1.02 if route_visit_count < 3 else 0.24
	return 0.22 if _has_weapon() else 0.12


func _has_weapon() -> bool:
	return _weapon_inventory != null and _weapon_inventory.has_weapon()


func _available_combat_target_count() -> int:
	var count := 0
	for target in get_tree().get_nodes_in_group("lyra_ai_combat_target"):
		if target is Node3D and (not target.has_method("is_alive") or bool(target.call("is_alive"))):
			count += 1
	return count


func _available_waypoint_count() -> int:
	return get_tree().get_nodes_in_group("lyra_ai_waypoint").size()


func _available_build_site_count() -> int:
	var count := 0
	for site in get_tree().get_nodes_in_group("lyra_ai_build_site"):
		if site is Node3D and site.has_method("needs_resources") and bool(site.call("needs_resources")):
			count += 1
	return count


func _try_fire_at_combat_target(target: Node3D) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {"shot": "no_target"}
	if _weapon_inventory == null or not _weapon_inventory.has_weapon():
		return {"shot": "no_weapon"}

	var weapon_master := _weapon_inventory.get_weapon_master()
	var weapon_resource := _weapon_inventory.current_weapon
	if weapon_master == null or weapon_resource == null or not weapon_master.has_method("fire"):
		return {"shot": "no_weapon_master"}

	_face_position(target.global_position)
	if not bool(weapon_master.call("fire")):
		return {"shot": "cooldown", "target": target.name}

	var muzzle := weapon_master.get_node_or_null("Muzzle") as Node3D
	var origin := muzzle.global_position if muzzle else global_position + Vector3(0.0, 1.2, 0.0)
	var aim_point := target.global_position + Vector3(0.0, 1.0, 0.0)
	var hit_target := _ray_hits_target(origin, aim_point, target)
	var result := "hit" if hit_target else "miss"
	var damage := weapon_resource.damage if weapon_resource else 1.0
	if hit_target and target.has_method("take_damage"):
		target.call("take_damage", damage, self)
	_log_shot(weapon_resource, target, result, damage, origin.distance_to(aim_point))
	return {
		"shot": result,
		"weapon": weapon_resource.weapon_name,
		"damage": damage if hit_target else 0.0,
	}


func _ray_hits_target(origin: Vector3, aim_point: Vector3, target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(origin, aim_point)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	return hit.get("collider") == target


func _face_position(target_position: Vector3) -> void:
	var flat_offset := target_position - global_position
	flat_offset.y = 0.0
	if flat_offset.length() <= 0.01:
		return
	rotation.y = atan2(flat_offset.x, flat_offset.z)


func _log_shot(weapon_resource: WeaponResource, target: Node3D, result: String, damage: float, distance: float) -> void:
	_log({
		"type": "shot_fired",
		"actor": name,
		"role": role,
		"goal": current_goal,
		"target": target.name if target else "",
		"weapon": weapon_resource.weapon_name if weapon_resource else "",
		"result": result,
		"damage": damage if result == "hit" else 0.0,
		"distance_to_target": distance,
	})


func _log_route_visit() -> void:
	_log({
		"type": "route_visit",
		"actor": name,
		"role": role,
		"goal": current_goal,
		"target": current_target.name if current_target else "",
		"visit_count": route_visit_count,
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
	})


func _log_build_progress(build_result: Dictionary) -> void:
	if int(build_result.get("delivered_resources", 0)) == 1:
		_log_build_event("build_started", build_result)
	_log_build_event("build_resource_delivered", build_result)
	if str(build_result.get("build", "")) == "completed":
		_log_build_event("build_completed", build_result)


func _log_build_event(event_type: String, build_result: Dictionary) -> void:
	_log({
		"type": event_type,
		"actor": name,
		"role": role,
		"goal": current_goal,
		"target": current_target.name if current_target else str(build_result.get("target", "")),
		"delivered_resources": int(build_result.get("delivered_resources", 0)),
		"required_resources": int(build_result.get("required_resources", 0)),
		"is_complete": bool(build_result.get("is_complete", false)),
		"position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
	})


func _target_weapon_name(target: Node) -> String:
	if target == null:
		return ""
	var weapon_resource := target.get("weapon_resource") as WeaponResource
	if weapon_resource:
		return weapon_resource.weapon_name
	return target.name
