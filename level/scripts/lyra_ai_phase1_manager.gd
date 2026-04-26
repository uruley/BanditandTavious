extends Node3D

const TARGET_SCRIPT := preload("res://level/scripts/lyra_ai_target.gd")
const ACTOR_SCRIPT := preload("res://level/scripts/lyra_ai_actor.gd")
const TASK_BOARD_SCRIPT := preload("res://level/scripts/lyra_ai_task_board.gd")
const METRICS_SCRIPT := preload("res://level/scripts/lyra_ai_metrics.gd")
const MEMORY_STORE_SCRIPT := preload("res://level/scripts/lyra_ai_memory_store.gd")
const COMBAT_TARGET_SCRIPT := preload("res://level/scripts/lyra_ai_combat_target.gd")
const WAYPOINT_SCRIPT := preload("res://level/scripts/lyra_ai_waypoint.gd")
const BUILD_SITE_SCRIPT := preload("res://level/scripts/lyra_ai_build_site.gd")
const PISTOL_PICKUP_SCENE := preload("res://level/scenes/weapons/PistolPickup.tscn")
const RIFLE_PICKUP_SCENE := preload("res://level/scenes/weapons/RiflePickup.tscn")

@export var enabled: bool = true
@export var actor_count: int = 6
@export var test_duration_sec: float = 0.0
@export var use_runtime_test_pad: bool = false
@export var use_broad_sandbox_nav: bool = true

var _frame_sample_timer: float = 0.0
var _elapsed: float = 0.0
var _decision_count_last_frame: int = 0
var _nav_vertex_lookup: Dictionary = {}
var _seed_override: int = -1
var _metrics_path_override: String = ""
var _memory_path_override: String = ""
var _reset_ai_memory: bool = false
var metrics: Node
var memory_store: Node


func _ready() -> void:
	if not enabled:
		return
	_apply_cli_args()
	if _seed_override >= 0:
		seed(_seed_override)
	else:
		randomize()
	_ensure_core_nodes()
	_ensure_navigation_surface()
	_ensure_weapon_pickups()
	_ensure_targets()
	_ensure_combat_targets()
	_ensure_waypoints()
	_ensure_build_sites()
	_spawn_actors()


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_elapsed += delta
	_frame_sample_timer -= delta
	if _frame_sample_timer <= 0.0:
		_log_frame_sample()
		_frame_sample_timer = 2.0
	if test_duration_sec > 0.0 and _elapsed >= test_duration_sec:
		get_tree().quit()


func _ensure_core_nodes() -> void:
	if get_node_or_null("AIMemoryStore") == null:
		var memory_node := Node.new()
		memory_node.name = "AIMemoryStore"
		memory_node.set_script(MEMORY_STORE_SCRIPT)
		memory_node.set("reset_on_start", _reset_ai_memory)
		if _memory_path_override != "":
			memory_node.set("memory_path", _memory_path_override)
		add_child(memory_node)
		memory_store = memory_node
	else:
		memory_store = get_node("AIMemoryStore")
		memory_store.set("reset_on_start", _reset_ai_memory)
		if _memory_path_override != "":
			memory_store.set("memory_path", _memory_path_override)

	if get_node_or_null("TaskBoard") == null:
		var task_board := Node.new()
		task_board.name = "TaskBoard"
		task_board.set_script(TASK_BOARD_SCRIPT)
		add_child(task_board)

	if get_node_or_null("AIMetrics") == null:
		var metrics_node := Node.new()
		metrics_node.name = "AIMetrics"
		metrics_node.set_script(METRICS_SCRIPT)
		if _metrics_path_override != "":
			metrics_node.set("metrics_path", _metrics_path_override)
		add_child(metrics_node)
		metrics = metrics_node
	else:
		metrics = get_node("AIMetrics")
		if _metrics_path_override != "":
			metrics.set("metrics_path", _metrics_path_override)

	if memory_store != null and memory_store.has_method("emit_status"):
		memory_store.call("emit_status", metrics)


func _ensure_targets() -> void:
	var targets_root := get_node_or_null("Targets") as Node3D
	if targets_root != null:
		_configure_existing_targets(targets_root)
		_ensure_catalog_targets(targets_root)
		return

	targets_root = Node3D.new()
	targets_root.name = "Targets"
	add_child(targets_root)

	_ensure_catalog_targets(targets_root)


func _configure_existing_targets(targets_root: Node3D) -> void:
	for child in targets_root.get_children():
		var target := child as Area3D
		if target == null:
			continue
		if target.get_script() == null:
			target.set_script(TARGET_SCRIPT)


func _ensure_catalog_targets(targets_root: Node3D) -> void:
	for target_def in _target_definitions():
		var target_name := str(target_def["name"])
		var target := targets_root.get_node_or_null(target_name) as Area3D
		if target == null:
			_create_target(
				targets_root,
				target_name,
				str(target_def["type"]),
				target_def["position"],
				target_def["color"],
				int(target_def["capacity"])
			)
		else:
			_configure_target(target, target_def)


func _target_definitions() -> Array[Dictionary]:
	return [
		{"name": "Food_01", "type": "food", "position": Vector3(3.5, 0.35, 8.0), "color": Color(0.25, 0.95, 0.25, 1.0), "capacity": 2},
		{"name": "Food_02", "type": "food", "position": Vector3(10.0, 0.35, 16.0), "color": Color(0.25, 0.95, 0.25, 1.0), "capacity": 2},
		{"name": "Food_03", "type": "food", "position": Vector3(24.0, 0.35, 8.5), "color": Color(0.25, 0.95, 0.25, 1.0), "capacity": 2},
		{"name": "Food_04", "type": "food", "position": Vector3(30.0, 0.35, 20.0), "color": Color(0.25, 0.95, 0.25, 1.0), "capacity": 2},
		{"name": "Food_05", "type": "food", "position": Vector3(-10.0, 0.35, 39.0), "color": Color(0.25, 0.95, 0.25, 1.0), "capacity": 2},
		{"name": "Water_01", "type": "water", "position": Vector3(8.8, 0.35, 18.8), "color": Color(0.2, 0.55, 1.0, 1.0), "capacity": 2},
		{"name": "Water_02", "type": "water", "position": Vector3(13.0, 0.35, 7.0), "color": Color(0.2, 0.55, 1.0, 1.0), "capacity": 2},
		{"name": "Water_03", "type": "water", "position": Vector3(26.0, 0.35, 24.0), "color": Color(0.2, 0.55, 1.0, 1.0), "capacity": 2},
		{"name": "Water_04", "type": "water", "position": Vector3(1.0, 0.35, 22.0), "color": Color(0.2, 0.55, 1.0, 1.0), "capacity": 2},
		{"name": "Water_05", "type": "water", "position": Vector3(47.0, 0.35, 34.0), "color": Color(0.2, 0.55, 1.0, 1.0), "capacity": 2},
		{"name": "Resource_01", "type": "resource", "position": Vector3(5.5, 0.35, 11.0), "color": Color(1.0, 0.78, 0.2, 1.0), "capacity": 2},
		{"name": "Resource_02", "type": "resource", "position": Vector3(17.5, 0.35, 15.5), "color": Color(1.0, 0.78, 0.2, 1.0), "capacity": 2},
		{"name": "Resource_03", "type": "resource", "position": Vector3(24.0, 0.35, 18.0), "color": Color(1.0, 0.78, 0.2, 1.0), "capacity": 2},
		{"name": "Resource_04", "type": "resource", "position": Vector3(30.0, 0.35, 27.0), "color": Color(1.0, 0.78, 0.2, 1.0), "capacity": 2},
		{"name": "Resource_05", "type": "resource", "position": Vector3(44.0, 0.35, 6.0), "color": Color(1.0, 0.78, 0.2, 1.0), "capacity": 2},
	]


func _spawn_actors() -> void:
	if has_node("Actors"):
		return

	var actors_root := Node3D.new()
	actors_root.name = "Actors"
	add_child(actors_root)

	for i in actor_count:
		var actor := CharacterBody3D.new()
		actor.name = "Gatherer_%02d" % [i + 1]
		actor.position = Vector3(4.0 + (i % 3) * 2.0, 1.8, 8.5 + (i / 3) * 2.0)
		actor.set_script(ACTOR_SCRIPT)
		actor.set("role", _role_for_index(i))
		actor.set("body_color", Color.from_hsv(float(i) / maxf(float(actor_count), 1.0), 0.65, 0.95, 1.0))
		actors_root.add_child(actor)


func _ensure_navigation_surface() -> void:
	if use_runtime_test_pad:
		_spawn_test_pad()
	else:
		_spawn_sandbox_nav_region()


func _spawn_test_pad() -> void:
	if has_node("AITestPad"):
		return

	var pad := StaticBody3D.new()
	pad.name = "AITestPad"
	pad.position = Vector3(-15.0, -0.08, 12.0)
	add_child(pad)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PadMesh"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(18.0, 0.16, 12.0)
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.16, 0.13, 1.0)
	mesh_instance.material_override = material
	pad.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(18.0, 0.16, 12.0)
	collision.shape = shape
	pad.add_child(collision)

	var nav_region := NavigationRegion3D.new()
	nav_region.name = "AINavigationRegion"
	nav_region.position = Vector3(-15.0, 0.04, 12.0)
	var nav_mesh := NavigationMesh.new()
	nav_mesh.vertices = PackedVector3Array([
		Vector3(-9.0, 0.0, -6.0),
		Vector3(9.0, 0.0, -6.0),
		Vector3(9.0, 0.0, 6.0),
		Vector3(-9.0, 0.0, 6.0),
	])
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)


func _spawn_sandbox_nav_region() -> void:
	if has_node("AISandboxNavigationRegion"):
		return

	var nav_region := NavigationRegion3D.new()
	nav_region.name = "AISandboxNavigationRegion"
	nav_region.position = Vector3(0.0, 0.35, 0.0)
	var nav_mesh := NavigationMesh.new()
	if use_broad_sandbox_nav:
		_build_broad_sandbox_nav(nav_mesh)
	else:
		_add_nav_quad(nav_mesh, Vector3(1.5, 0.0, 6.0), Vector3(15.0, 0.0, 17.0))
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)


func _build_broad_sandbox_nav(nav_mesh: NavigationMesh) -> void:
	_nav_vertex_lookup.clear()
	var x_edges := [-14.0, -6.0, 8.0, 20.0, 32.0, 44.0, 52.0]
	var z_edges := [0.0, 4.0, 14.0, 22.0, 30.0, 38.0, 46.0]
	for x_index in range(x_edges.size() - 1):
		for z_index in range(z_edges.size() - 1):
			_add_nav_quad(
				nav_mesh,
				Vector3(x_edges[x_index], 0.0, z_edges[z_index]),
				Vector3(x_edges[x_index + 1], 0.0, z_edges[z_index + 1])
			)


func _add_nav_quad(nav_mesh: NavigationMesh, min_point: Vector3, max_point: Vector3) -> void:
	var a := _nav_vertex_index(nav_mesh, Vector3(min_point.x, min_point.y, min_point.z))
	var b := _nav_vertex_index(nav_mesh, Vector3(max_point.x, min_point.y, min_point.z))
	var c := _nav_vertex_index(nav_mesh, Vector3(max_point.x, max_point.y, max_point.z))
	var d := _nav_vertex_index(nav_mesh, Vector3(min_point.x, max_point.y, max_point.z))
	nav_mesh.add_polygon(PackedInt32Array([a, b, c, d]))


func _nav_vertex_index(nav_mesh: NavigationMesh, point: Vector3) -> int:
	var key := "%.3f:%.3f:%.3f" % [point.x, point.y, point.z]
	if _nav_vertex_lookup.has(key):
		return int(_nav_vertex_lookup[key])
	var vertices := nav_mesh.vertices
	var index := vertices.size()
	vertices.append(point)
	nav_mesh.vertices = vertices
	_nav_vertex_lookup[key] = index
	return index


func _create_target(parent: Node3D, target_name: String, target_type: String, position: Vector3, color: Color, capacity: int = 1) -> void:
	var target := Area3D.new()
	target.name = target_name
	target.set_script(TARGET_SCRIPT)
	parent.add_child(target)
	_configure_target(target, {
		"name": target_name,
		"type": target_type,
		"position": position,
		"color": color,
		"capacity": capacity,
	})


func _configure_target(target: Area3D, target_def: Dictionary) -> void:
	target.position = target_def["position"]
	target.set("target_type", str(target_def["type"]))
	target.set("label_text", str(target_def["name"]))
	target.set("marker_color", target_def["color"])
	target.set("capacity", int(target_def["capacity"]))


func _ensure_weapon_pickups() -> void:
	if has_node("AIWeaponPickups"):
		return
	var pickup_root := Node3D.new()
	pickup_root.name = "AIWeaponPickups"
	add_child(pickup_root)
	_spawn_weapon_pickup(pickup_root, "AI_PistolPickup_01", PISTOL_PICKUP_SCENE, Vector3(7.0, 0.9, 6.2))
	_spawn_weapon_pickup(pickup_root, "AI_RiflePickup_01", RIFLE_PICKUP_SCENE, Vector3(18.0, 0.9, 12.0))
	_spawn_weapon_pickup(pickup_root, "AI_PistolPickup_02", PISTOL_PICKUP_SCENE, Vector3(25.0, 0.9, 20.0))


func _spawn_weapon_pickup(parent: Node3D, pickup_name: String, pickup_scene: PackedScene, position: Vector3) -> void:
	var pickup := pickup_scene.instantiate() as Node3D
	if pickup == null:
		return
	pickup.name = pickup_name
	pickup.position = position
	pickup.set("auto_pickup", false)
	parent.add_child(pickup)


func _ensure_combat_targets() -> void:
	if has_node("AICombatTargets"):
		return
	var target_root := Node3D.new()
	target_root.name = "AICombatTargets"
	add_child(target_root)
	_spawn_combat_target(target_root, "AI_TargetDummy_01", Vector3(28.0, 0.35, 10.5))
	_spawn_combat_target(target_root, "AI_TargetDummy_02", Vector3(46.0, 0.35, 8.0))


func _spawn_combat_target(parent: Node3D, target_name: String, position: Vector3) -> void:
	var target := StaticBody3D.new()
	target.name = target_name
	target.set_script(COMBAT_TARGET_SCRIPT)
	target.position = position

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.45
	mesh.bottom_radius = 0.45
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.9, 0.0)
	target.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := CylinderShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	collision.shape = shape
	collision.position = Vector3(0.0, 0.9, 0.0)
	target.add_child(collision)

	var label := Label3D.new()
	label.name = "Label3D"
	label.text = target_name
	label.position = Vector3(0.0, 2.25, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	target.add_child(label)

	parent.add_child(target)


func _ensure_waypoints() -> void:
	var waypoint_root := get_node_or_null("AINavWaypoints") as Node3D
	if waypoint_root == null:
		waypoint_root = Node3D.new()
		waypoint_root.name = "AINavWaypoints"
		add_child(waypoint_root)

	for waypoint_def in _waypoint_definitions():
		var waypoint_name := str(waypoint_def["name"])
		var waypoint := waypoint_root.get_node_or_null(waypoint_name) as Node3D
		if waypoint == null:
			waypoint = Node3D.new()
			waypoint.name = waypoint_name
			waypoint.set_script(WAYPOINT_SCRIPT)
			waypoint_root.add_child(waypoint)
		waypoint.position = waypoint_def["position"]
		waypoint.set("label_text", waypoint_name)
		waypoint.set("marker_color", waypoint_def["color"])


func _ensure_build_sites() -> void:
	var build_root := get_node_or_null("AIBuildSites") as Node3D
	if build_root == null:
		build_root = Node3D.new()
		build_root.name = "AIBuildSites"
		add_child(build_root)

	for build_def in _build_site_definitions():
		var build_name := str(build_def["name"])
		var build_site := build_root.get_node_or_null(build_name) as Node3D
		if build_site == null:
			build_site = Node3D.new()
			build_site.name = build_name
			build_site.set_script(BUILD_SITE_SCRIPT)
			build_root.add_child(build_site)
		build_site.position = build_def["position"]
		build_site.set("label_text", build_name)
		build_site.set("required_resources", int(build_def["required_resources"]))
		build_site.set("marker_size", build_def["marker_size"])


func _waypoint_definitions() -> Array[Dictionary]:
	return [
		{"name": "WP_SpawnLane", "position": Vector3(6.0, 0.35, 9.0), "color": Color(0.45, 0.85, 1.0, 1.0)},
		{"name": "WP_CentralMarket", "position": Vector3(20.0, 0.35, 15.0), "color": Color(0.45, 0.85, 1.0, 1.0)},
		{"name": "WP_EastGate", "position": Vector3(28.0, 0.35, 12.0), "color": Color(0.45, 0.85, 1.0, 1.0)},
		{"name": "WP_EastOuter", "position": Vector3(47.0, 0.35, 8.0), "color": Color(0.35, 0.95, 0.95, 1.0)},
		{"name": "WP_NorthEast", "position": Vector3(47.0, 0.35, 34.0), "color": Color(0.35, 0.95, 0.95, 1.0)},
		{"name": "WP_NorthCrossing", "position": Vector3(22.0, 0.35, 34.0), "color": Color(0.35, 0.95, 0.95, 1.0)},
		{"name": "WP_NorthWest", "position": Vector3(-10.0, 0.35, 39.0), "color": Color(0.35, 0.95, 0.95, 1.0)},
		{"name": "WP_WestLane", "position": Vector3(-10.0, 0.35, 18.0), "color": Color(0.35, 0.95, 0.95, 1.0)},
	]


func _build_site_definitions() -> Array[Dictionary]:
	return [
		{
			"name": "BuildSite_Barricade_01",
			"position": Vector3(21.5, 0.35, 20.0),
			"required_resources": 2,
			"marker_size": Vector3(2.8, 0.12, 0.9),
		},
	]


func _log_frame_sample() -> void:
	if metrics == null or not metrics.has_method("log_event"):
		return
	metrics.call("log_event", {
		"type": "frame_sample",
		"active_ai_count": get_tree().get_nodes_in_group("lyra_ai_actor").size(),
		"fps": Engine.get_frames_per_second(),
		"physics_fps": Engine.physics_ticks_per_second,
		"frame_time_ms": 1000.0 / maxf(float(Engine.get_frames_per_second()), 1.0),
		"decision_count": _decision_count_last_frame,
		"interaction_count": 0,
	})
	_decision_count_last_frame = 0


func _apply_cli_args() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var arg := str(args[i])
		if arg == "--ai-test" and test_duration_sec <= 0.0:
			test_duration_sec = 20.0
		elif arg == "--duration" and i + 1 < args.size():
			test_duration_sec = maxf(float(str(args[i + 1]).to_float()), 1.0)
		elif arg == "--ai-count" and i + 1 < args.size():
			actor_count = max(1, str(args[i + 1]).to_int())
		elif arg == "--ai-test-pad":
			use_runtime_test_pad = true
		elif arg == "--ai-local-nav":
			use_broad_sandbox_nav = false
		elif arg == "--seed" and i + 1 < args.size():
			_seed_override = maxi(str(args[i + 1]).to_int(), 0)
		elif arg == "--metrics-path" and i + 1 < args.size():
			_metrics_path_override = str(args[i + 1])
		elif arg == "--memory-path" and i + 1 < args.size():
			_memory_path_override = str(args[i + 1])
		elif arg == "--reset-ai-memory":
			_reset_ai_memory = true


func _role_for_index(index: int) -> String:
	var roles := ["forager", "hauler", "scout"]
	return roles[index % roles.size()]
