extends Area3D

@export var speed := 45.0
@export var lifetime := 2.0
@export var radius := 0.05
@export var direction := Vector3.FORWARD

var _time_left := 0.0
@onready var collision_shape: CollisionShape3D = get_node_or_null("Hitbox")
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 1
	_time_left = lifetime

	if collision_shape:
		var sphere_shape := collision_shape.shape as SphereShape3D
		if sphere_shape:
			sphere_shape.radius = radius
	if mesh_instance:
		var sphere_mesh := mesh_instance.mesh as SphereMesh
		if sphere_mesh:
			sphere_mesh.radius = radius
			sphere_mesh.height = radius * 2.0

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()

func _on_body_entered(_body: Node) -> void:
	queue_free()

func _on_area_entered(_area: Area3D) -> void:
	queue_free()
