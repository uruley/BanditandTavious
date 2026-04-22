extends Node3D

@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var floor: CSGBox3D = $Floor
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_configure_light()
	_configure_floor()
	_configure_camera()


func _configure_light() -> void:
	sun.position = Vector3(0.0, 6.0, 0.0)
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)


func _configure_floor() -> void:
	var floor_size := Vector3(20.0, 1.0, 20.0)
	floor.size = floor_size
	floor.position = Vector3(0.0, -0.5, 0.0)
	floor.use_collision = true

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.2, 0.22, 1.0)
	material.roughness = 0.95
	floor.material = material


func _configure_camera() -> void:
	camera.current = true
	camera.position = Vector3(0.0, 9.0, 12.5)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
