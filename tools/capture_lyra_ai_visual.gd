extends SceneTree

const DEFAULT_SCENE := "res://level/scenes/lyrasandbox.tscn"
const DEFAULT_CAPTURE_PATH := "res://logs/lyra_ai_visual_capture.png"


func _initialize() -> void:
	_run_capture.call_deferred()


func _run_capture() -> void:
	var capture_path := _arg_value("--capture-path", DEFAULT_CAPTURE_PATH)
	var scene_path := _arg_value("--scene", DEFAULT_SCENE)
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		quit(1)
		return

	var scene := packed_scene.instantiate() as Node3D
	root.add_child(scene)
	current_scene = scene

	var menu := scene.get_node_or_null("Menu") as CanvasItem
	if menu != null:
		menu.hide()

	await process_frame
	await create_timer(2.5).timeout

	var actors := get_nodes_in_group("lyra_ai_actor")
	if actors.is_empty():
		push_error("No nodes found in group lyra_ai_actor.")
		quit(1)
		return

	var actor := actors[0] as Node3D
	if actor == null:
		push_error("First lyra_ai_actor is not a Node3D.")
		quit(1)
		return

	var camera := Camera3D.new()
	camera.name = "NeoVisualEvidenceCamera"
	camera.fov = 48.0
	camera.near = 0.05
	camera.far = 200.0
	scene.add_child(camera)

	var target := actor.global_position + Vector3(0.0, 1.3, 0.0)
	camera.global_position = target + Vector3(3.5, 2.2, 5.0)
	camera.look_at(target, Vector3.UP)
	camera.make_current()

	var light := DirectionalLight3D.new()
	light.name = "NeoVisualEvidenceLight"
	light.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	light.light_energy = 2.0
	scene.add_child(light)

	await process_frame
	await process_frame

	var image := root.get_viewport().get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(capture_path)
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("Failed to save visual capture to %s: %s" % [absolute_path, error])
		quit(1)
		return

	print("NEO_VISUAL_CAPTURE actor=%s path=%s" % [actor.name, absolute_path])
	quit(0)


func _arg_value(name: String, default_value: String) -> String:
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if str(args[index]) == name and index + 1 < args.size():
			return str(args[index + 1])
	return default_value
