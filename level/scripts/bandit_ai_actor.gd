extends CharacterBody3D

enum Role {
	ENEMY,
	FRIENDLY,
	VILLAGER,
}

const GRAVITY := 18.0
const CAPSULE_HEIGHT := 1.8
const CAPSULE_RADIUS := 0.45
const FRIENDLY_DEFEND_RANGE := 5.5
const ENEMY_ATTACK_RANGE := 1.35
const VILLAGER_FLEE_RANGE := 6.0
const MIN_TARGET_DISTANCE := 0.25

@export var role: Role = Role.ENEMY
@export var move_speed: float = 3.4
@export var detection_range: float = 8.0
@export var wander_radius: float = 3.0
@export var body_color: Color = Color.WHITE

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

var home_position: Vector3
var target_point: Vector3
var target_actor: CharacterBody3D
var retarget_timer: float = 0.0


func _ready() -> void:
	home_position = global_position
	target_point = home_position
	_configure_visuals()
	add_to_group("bandit_ai_actor")
	retarget_timer = randf_range(0.1, 0.45)


func _physics_process(delta: float) -> void:
	retarget_timer -= delta
	velocity.y -= GRAVITY * delta

	if retarget_timer <= 0.0:
		_pick_behavior_target()
		retarget_timer = _get_retarget_interval()

	var desired_velocity := _get_desired_velocity()
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z

	if desired_velocity.length() > 0.05:
		var facing := atan2(desired_velocity.x, desired_velocity.z)
		rotation.y = lerp_angle(rotation.y, facing, delta * 8.0)

	move_and_slide()


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

	var material := StandardMaterial3D.new()
	material.albedo_color = body_color
	material.roughness = 0.82
	body_mesh.material_override = material


func _pick_behavior_target() -> void:
	match role:
		Role.ENEMY:
			target_actor = _find_nearest_actor([Role.FRIENDLY, Role.VILLAGER], detection_range)
			if target_actor:
				target_point = target_actor.global_position
			else:
				target_actor = null
				if global_position.distance_to(target_point) < 1.0:
					_pick_wander_target()
		Role.FRIENDLY:
			var villager: CharacterBody3D = _find_nearest_actor([Role.VILLAGER], 20.0)
			var enemy: CharacterBody3D = _find_nearest_actor([Role.ENEMY], FRIENDLY_DEFEND_RANGE)
			target_actor = enemy if enemy else villager
			if target_actor:
				if enemy:
					target_point = enemy.global_position
				else:
					var escort_angle := Time.get_ticks_msec() * 0.0015
					var escort_offset := Vector3(cos(escort_angle), 0.0, sin(escort_angle)) * 1.8
					target_point = villager.global_position + escort_offset
			else:
				target_actor = null
				if global_position.distance_to(target_point) < 1.0:
					_pick_wander_target()
		Role.VILLAGER:
			target_actor = _find_nearest_actor([Role.ENEMY], VILLAGER_FLEE_RANGE)
			if target_actor:
				var flee_direction: Vector3 = (global_position - target_actor.global_position).normalized()
				target_point = home_position + (flee_direction * wander_radius)
			else:
				target_actor = null
				if global_position.distance_to(target_point) < 1.0:
					_pick_wander_target()


func _pick_wander_target() -> void:
	var offset := Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	target_point = home_position + offset


func _get_desired_velocity() -> Vector3:
	var flat_target := target_point
	flat_target.y = global_position.y
	var to_target := flat_target - global_position
	var distance := to_target.length()

	if role == Role.ENEMY and target_actor and distance < ENEMY_ATTACK_RANGE:
		return Vector3.ZERO

	if distance < MIN_TARGET_DISTANCE:
		return Vector3.ZERO

	return to_target.normalized() * move_speed


func _get_retarget_interval() -> float:
	match role:
		Role.ENEMY:
			return 0.25
		Role.FRIENDLY:
			return 0.4
		Role.VILLAGER:
			return 1.2
	return 0.5


func get_ai_snapshot() -> Dictionary:
	var target_distance := global_position.distance_to(target_point)
	return {
		"name": name,
		"role": int(role),
		"position": global_position,
		"velocity": velocity,
		"target_point": target_point,
		"target_name": target_actor.name if target_actor else "",
		"state": _get_state_label(target_distance),
		"distance_to_target": target_distance,
	}


func _get_state_label(target_distance: float) -> String:
	match role:
		Role.ENEMY:
			if target_actor and target_distance < ENEMY_ATTACK_RANGE:
				return "attack"
			if target_actor:
				return "chase"
			return "wander"
		Role.FRIENDLY:
			var target_role = target_actor.get("role") if target_actor else null
			if target_actor and target_role != null and int(target_role) == int(Role.ENEMY):
				return "defend"
			if target_actor:
				return "escort"
			return "wander"
		Role.VILLAGER:
			if target_actor:
				return "flee"
			return "wander"
	return "unknown"


func _find_nearest_actor(role_filter: Array, max_distance: float) -> CharacterBody3D:
	var nearest: CharacterBody3D
	var best_distance := max_distance

	for candidate_variant in get_tree().get_nodes_in_group("bandit_ai_actor"):
		var candidate := candidate_variant as CharacterBody3D
		if candidate == null or candidate == self:
			continue
		var candidate_role = candidate.get("role")
		if candidate_role == null:
			continue
		if candidate_role not in role_filter:
			continue

		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = candidate

	return nearest
