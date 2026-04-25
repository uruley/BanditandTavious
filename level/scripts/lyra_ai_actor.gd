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
const NAV_AGENT_NAME := "NavigationAgent3D"
const WEAPON_MASTER_SCENE := preload("res://level/scenes/weapons/WeaponMaster.tscn")

@export var move_speed: float = 3.2
@export var decision_interval: float = 1.0
@export var interact_distance: float = 1.25
@export var interact_duration: float = 1.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var hunger_rate: float = 2.0
@export var thirst_rate: float = 3.0
@export var body_color: Color = Color(0.9, 0.8, 0.25, 1.0)
@export_enum("forager", "hauler", "scout") var role: String = "forager"
@export var wants_weapon: bool = true

var hunger: float = 35.0
var thirst: float = 45.0
var resource_count: int = 0
var current_goal: String = ""
var current_target: Node3D
var state: int = State.IDLE
var decision_timer: float = 0.0
var interact_timer: float = 0.0
var stuck_seconds: float = 0.0
var _last_position: Vector3
var _last_nav_target: Vector3 = Vector3.INF
var _debug_label: Label3D
var _target_cooldowns: Dictionary = {}
var _weapon_inventory: WeaponInventoryComponent

@onready var task_board: Node = _find_first_group_node("lyra_ai_task_board")
@onready var metrics: Node = _find_first_group_node("lyra_ai_metrics")
@onready var navigation_agent: NavigationAgent3D = _ensure_navigation_agent()


func _ready() -> void:
	add_to_group("lyra_ai_actor")
	_last_position = global_position
	_configure_capsule()
	_ensure_weapon_inventory()
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


func _configure_capsule() -> void:
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
		"weapon": _weapon_score(),
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
		_log_reservation("failure", "no_available_target")
		state = State.IDLE
		decision_timer = decision_interval
		return

	_log_reservation("success", "nearest_available")
	_update_navigation_target()
	state = State.MOVE_TO_TARGET
	decision_timer = decision_interval


func _move_to_target(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
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
	if target_distance <= interact_distance or (navigation_agent.is_navigation_finished() and target_distance <= interact_distance * 1.5):
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
		"weapon":
			var weapon_name := _target_weapon_name(current_target)
			if current_target != null and current_target.has_method("interact") and bool(current_target.call("interact", self)):
				delta_state["weapon"] = weapon_name
			else:
				delta_state["weapon"] = "failed"
				_log_interaction(delta_state, "failure")
				_cooldown_current_target()
				_release_target()
				state = State.IDLE
				decision_timer = randf_range(0.35, decision_interval)
				return

	_log_interaction(delta_state)
	_release_target()
	state = State.IDLE
	decision_timer = randf_range(0.35, decision_interval)


func _track_stuck(delta: float) -> void:
	var moved := global_position.distance_to(_last_position)
	if state == State.MOVE_TO_TARGET and current_target != null and moved < 0.01:
		stuck_seconds += delta
		if stuck_seconds >= 2.0:
			_log_stuck()
			_cooldown_current_target()
			state = State.REPLAN
			stuck_seconds = 0.0
	else:
		stuck_seconds = 0.0
	_last_position = global_position


func _release_target() -> void:
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
	_debug_label.text = "%s\n%s -> %s\nH %.0f T %.0f R %d W %s" % [
		name,
		current_goal if current_goal != "" else "idle",
		target_name,
		hunger,
		thirst,
		resource_count,
		"yes" if _has_weapon() else "no",
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
		"scout":
			scores["resource"] = clampf(float(scores["resource"]) + 0.12, 0.0, 1.0)
			scores["weapon"] = clampf(float(scores["weapon"]) + 0.1, 0.0, 1.0)


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


func _weapon_score() -> float:
	if not wants_weapon or _has_weapon():
		return 0.05
	return 0.92


func _has_weapon() -> bool:
	return _weapon_inventory != null and _weapon_inventory.has_weapon()


func _target_weapon_name(target: Node) -> String:
	if target == null:
		return ""
	var weapon_resource := target.get("weapon_resource") as WeaponResource
	if weapon_resource:
		return weapon_resource.weapon_name
	return target.name
