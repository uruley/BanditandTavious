extends Node3D

@export var ai_scene: PackedScene = preload("res://level/scenes/bandit_ai_actor.tscn")
@export var destructible_scene: PackedScene = preload("res://level/scenes/DestructibleCube.tscn")

@onready var spawn_root := $SpawnRoot
@onready var world_env := $WorldEnvironment
@onready var directional_light := $DirectionalLight3D

var spawn_count := 0

func _ready() -> void:
	# Update paths if we are the parent of the named nodes
	if has_node("PerformanceStressTest"):
		spawn_root = get_node("PerformanceStressTest/SpawnRoot")
		world_env = get_node("PerformanceStressTest/WorldEnvironment")
		directional_light = get_node("PerformanceStressTest/DirectionalLight3D")

	if not spawn_root:
		spawn_root = Node3D.new()
		spawn_root.name = "SpawnRoot"
		add_child(spawn_root)
	
	_connect_ui()
	
	# Setup Environment
	if world_env and not world_env.environment:
		world_env.environment = Environment.new()
		world_env.environment.background_mode = Environment.BG_SKY
		world_env.environment.sky = Sky.new()
		world_env.environment.sky.sky_material = PanoramaSkyMaterial.new() # Or Procedural
	
	toggle_graphics(true)

	
	print("--- Performance Stress Test Sandbox Online ---")
	print("Press F9 to toggle Performance HUD")

func _connect_ui() -> void:
	var ui_path = "PerformanceStressTest/UI/VBoxContainer/" if has_node("PerformanceStressTest") else "UI/VBoxContainer/"
	
	get_node(ui_path + "SpawnAI100").pressed.connect(func(): spawn_ai_batch(100))
	get_node(ui_path + "SpawnDest50").pressed.connect(func(): spawn_destruction_batch(50))
	
	var graphics_btn = get_node(ui_path + "ToggleGraphics")
	var high_graphics := true
	graphics_btn.pressed.connect(func():
		high_graphics = !high_graphics
		toggle_graphics(high_graphics)
		graphics_btn.text = "Graphics: High" if high_graphics else "Graphics: Low"
	)
	
	var log_btn = get_node(ui_path + "ToggleLogging")
	log_btn.pressed.connect(func():
		if PerfMon.is_logging:
			PerfMon.stop_logging()
			log_btn.text = "Start Logging"
		else:
			PerfMon.start_logging()
			log_btn.text = "Stop Logging"
	)
	
	get_node(ui_path + "ClearAll").pressed.connect(clear_all)


func spawn_ai_batch(amount: int) -> void:
	print("Spawning ", amount, " AI actors...")
	var side = ceil(sqrt(amount))
	var spacing = 2.0
	for i in range(amount):
		var ai = ai_scene.instantiate()
		spawn_root.add_child(ai)
		var x = (i % int(side)) * spacing
		var z = floor(i / side) * spacing
		ai.global_position = Vector3(x - (side*0.5*spacing), 0.5, z - (side*0.5*spacing) + 10.0)
		spawn_count += 1

func spawn_destruction_batch(amount: int) -> void:
	print("Spawning ", amount, " destructibles...")
	var side = ceil(sqrt(amount))
	var spacing = 2.5
	for i in range(amount):
		var obj = destructible_scene.instantiate()
		spawn_root.add_child(obj)
		var x = (i % int(side)) * spacing
		var z = floor(i / side) * spacing
		obj.global_position = Vector3(x - (side*0.5*spacing), 5.0, z - (side*0.5*spacing) - 10.0)
		
		# Give it a tiny delay then explode
		get_tree().create_timer(randf_range(0.5, 2.0)).timeout.connect(func():
			if is_instance_valid(obj) and obj.has_method("destroy"):
				obj.destroy(Vector3.UP + Vector3(randf_range(-1,1), 0, randf_range(-1,1)))
		)
		spawn_count += 1

func toggle_graphics(high: bool) -> void:
	if not world_env: return
	
	var env = world_env.environment
	if high:
		env.sdfgi_enabled = true
		env.ssao_enabled = true
		env.ssil_enabled = true
		if directional_light:
			directional_light.shadow_enabled = true
		get_viewport().msaa_3d = Viewport.MSAA_4X
	else:
		env.sdfgi_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		if directional_light:
			directional_light.shadow_enabled = false
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED

func clear_all() -> void:
	for child in spawn_root.get_children():
		child.queue_free()
	spawn_count = 0
	# Also clear shards group
	for shard in get_tree().get_nodes_in_group("shards"):
		shard.queue_free()
