extends Area3D

@export var damage := 1.0
@export var speed := 45.0
@export var lifetime := 2.0
@export var radius := 0.05
@export var direction := Vector3.FORWARD
var shooter: Node = null

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

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		# If it's already at 0 or less, take_damage will call destroy()
		# But if we want to provide the direction, we can call destroy directly if it exists
		if body.has_method("destroy") and body.get("health") <= 0:
			body.destroy(direction.normalized())
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area == shooter:
		return
	if area.has_method("take_damage"):
		area.take_damage(damage)
		if area.has_method("destroy") and area.get("health") <= 0:
			area.destroy(direction.normalized())
	queue_free()
