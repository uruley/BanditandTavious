extends Node3D

@export var terrain: Terrain3D
@export var dig_radius: float = 3.0
@export var dig_depth: float = 0.5
@export var reach_distance: float = 50.0

@onready var camera = get_viewport().get_camera_3d()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_dig()

func _try_dig():
	# Update camera reference if needed
	if not camera:
		camera = get_viewport().get_camera_3d()
		
	if not terrain or not camera:
		return
		
	# Get mouse position and project a ray
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	# Create a RayQuery (Mask 1 for terrain/environment)
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * reach_distance, 1)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		_apply_dig(hit_pos)

func _apply_dig(pos: Vector3):
	# Try different common property names for Terrain3D storage/data
	var data = null
	if terrain.has_method("get_storage"):
		data = terrain.get_storage()
	elif "storage" in terrain:
		data = terrain.storage
	elif "data" in terrain:
		data = terrain.data
	
	if not data:
		print("Error: Terrain3D has no Data/Storage assigned!")
		return
	
	# Try common sculpting methods
	if data.has_method("add_height"):
		data.add_height(pos, -dig_depth, dig_radius)
	elif data.has_method("edit_height"):
		data.edit_height(pos, -dig_depth, dig_radius)
	else:
		print("Error: Could not find add_height or edit_height on Terrain3D data.")
