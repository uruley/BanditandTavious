extends CharacterBody3D

const GRAVITY := 18.0
const CAPSULE_HEIGHT := 1.8
const CAPSULE_RADIUS := 0.45
const ATTACK_RANGE := 1.35
const MIN_MOVE_DIST := 0.25
const ATTACK_TICK := 0.5

@export var move_speed: float = 3.6
@export var detection_range: float = 9.0
@export var wander_radius: float = 2.5
@export var shoot_cooldown: float = 1.5
@export var shoot_spread: float = 0.08
@export var body_color: Color = Color(0.75, 0.12, 0.12, 1.0)

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var home_position: Vector3
var target_point: Vector3
var target_actor: CharacterBody3D
var retarget_timer: float = 0.0
var shoot_timer: float = 0.0
var attack_tick_timer: float = 0.0

var shots_fired: int = 0
var shots_hit: int = 0
var attacks_landed: int = 0
var distance_traveled: float = 0.0
var _last_pos: Vector3


func _ready() -> void:
	home_position = global_position
	target_point = home_position
	_last_pos = global_position
	_configure_visuals()
	add_to_group("bandit_ai_actor")
	add_to_group("bandit_ai_enemy")
	add_to_group("training_agent")
	retarget_timer = randf_range(0.1, 0.45)


func _physics_process(delta: float) -> void:
	retarget_timer -= delta
	shoot_timer -= delta
	attack_tick_timer -= delta
	velocity.y -= GRAVITY * delta

	if retarget_timer <= 0.0:
		_pick_target()
		retarget_timer = 0.25

	_try_shoot()

	if target_actor and global_position.distance_to(target_actor.global_position) < ATTACK_RANGE:
		if attack_tick_timer <= 0.0:
			attacks_landed += 1
			attack_tick_timer = ATTACK_TICK

	distance_traveled += global_position.distance_to(_last_pos)
	_last_pos = global_position

	var dir := _move_direction()
	velocity.x = dir.x
	velocity.z = dir.z
	if dir.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
	move_and_slide()


func _pick_target() -> void:
	target_actor = _nearest(["bandit_ai_citizen", "bandit_ai_companion"], detection_range)
	if target_actor:
		target_point = target_actor.global_position
	else:
		if global_position.distance_to(target_point) < 1.0:
			_wander()


func _try_shoot() -> void:
	if shoot_timer > 0.0 or target_actor == null:
		return
	shoot_timer = shoot_cooldown
	shots_fired += 1

	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3(0.0, 1.2, 0.0)
	var aim := target_actor.global_position + Vector3(0.0, 0.9, 0.0)
	aim += Vector3(randf_range(-shoot_spread, shoot_spread), 0.0, randf_range(-shoot_spread, shoot_spread)) * eye.distance_to(aim)

	var query := PhysicsRayQueryParameters3D.create(eye, aim)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit and hit.collider == target_actor:
		shots_hit += 1


func _move_direction() -> Vector3:
	var flat := Vector3(target_point.x, global_position.y, target_point.z)
	var to := flat - global_position
	var dist := to.length()
	if dist < MIN_MOVE_DIST:
		return Vector3.ZERO
	if target_actor and dist < ATTACK_RANGE:
		return Vector3(-to.z, 0.0, to.x).normalized() * move_speed * 0.6
	return to.normalized() * move_speed


func _wander() -> void:
	target_point = home_position + Vector3(randf_range(-wander_radius, wander_radius), 0.0, randf_range(-wander_radius, wander_radius))


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


func get_fitness_score() -> float:
	var accuracy := float(shots_hit) / float(shots_fired) if shots_fired > 0 else 0.0
	return attacks_landed * 8.0 + shots_hit * 5.0 + accuracy * 25.0 + distance_traveled * 0.04


func reset_for_episode(params: Dictionary, spawn_pos: Vector3) -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	home_position = spawn_pos
	target_point = spawn_pos
	target_actor = null
	_last_pos = spawn_pos
	shoot_timer = 0.0
	attack_tick_timer = 0.0
	shots_fired = 0
	shots_hit = 0
	attacks_landed = 0
	distance_traveled = 0.0
	for key in params:
		set(key, params[key])
	_configure_visuals()


func get_ai_snapshot() -> Dictionary:
	return {"name": name, "role": "enemy", "position": global_position,
		"shots_fired": shots_fired, "shots_hit": shots_hit, "attacks_landed": attacks_landed}
