extends CharacterBody3D

const GRAVITY := 18.0
const CAPSULE_HEIGHT := 1.8
const CAPSULE_RADIUS := 0.45
const FLEE_RANGE := 6.0
const MIN_MOVE_DIST := 0.25

@export var move_speed: float = 2.6
@export var detection_range: float = 6.5
@export var wander_radius: float = 4.0
@export var body_color: Color = Color(0.92, 0.76, 0.26, 1.0)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var home_position: Vector3
var target_point: Vector3
var threat_actor: CharacterBody3D
var retarget_timer: float = 0.0


func _ready() -> void:
	home_position = global_position
	target_point = home_position
	_configure_visuals()
	add_to_group("bandit_ai_actor")
	add_to_group("bandit_ai_citizen")
	retarget_timer = randf_range(0.1, 0.45)


func _physics_process(delta: float) -> void:
	retarget_timer -= delta
	velocity.y -= GRAVITY * delta

	if retarget_timer <= 0.0:
		_pick_target()
		retarget_timer = 1.2

	var dir := _move_direction()
	velocity.x = dir.x
	velocity.z = dir.z

	if dir.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)

	move_and_slide()


func _pick_target() -> void:
	threat_actor = _nearest(["bandit_ai_enemy"], FLEE_RANGE)
	if threat_actor:
		var flee_dir := (global_position - threat_actor.global_position).normalized()
		target_point = global_position + flee_dir * wander_radius * 2.0
	else:
		if global_position.distance_to(target_point) < 1.0:
			_wander()


func _move_direction() -> Vector3:
	var flat := Vector3(target_point.x, global_position.y, target_point.z)
	var to := flat - global_position
	if to.length() < MIN_MOVE_DIST:
		return Vector3.ZERO
	return to.normalized() * move_speed


func _wander() -> void:
	target_point = home_position + Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)


func _configure_visuals() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.height = CAPSULE_HEIGHT
	capsule.radius = CAPSULE_RADIUS
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var mesh := CapsuleMesh.new()
	mesh.height = CAPSULE_HEIGHT
	mesh.radius = CAPSULE_RADIUS
	body_mesh.mesh = mesh
	body_mesh.position = Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.82
	body_mesh.material_override = mat


func _nearest(groups: Array[String], max_dist: float) -> CharacterBody3D:
	var nearest: CharacterBody3D
	var best := max_dist
	for group in groups:
		for node in get_tree().get_nodes_in_group(group):
			var c := node as CharacterBody3D
			if c == null or c == self:
				continue
			var d := global_position.distance_to(c.global_position)
			if d < best:
				best = d
				nearest = c
	return nearest


func get_ai_snapshot() -> Dictionary:
	return {
		"name": name,
		"role": "citizen",
		"position": global_position,
		"state": "flee" if threat_actor else "wander",
		"target": threat_actor.name if threat_actor else "",
	}
