extends CharacterBody3D


const SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSIBILITY = 0.005
const MIN_PITCH = -PI / 4.0
const MAX_PITCH = PI / 6.0
const TRIGGER_THRESHOLD = 0.5
const AIM_TRIGGER_THRESHOLD = 0.5
const CROUCH_SPEED = 2.5
const PROJECTILE_SPEED = 45.0
const PROJECTILE_RANGE = 200.0
const RECOIL_POSITION_KICK = Vector3(0.0, 0.015, 0.08)
const RECOIL_ROTATION_KICK = Vector3(-0.16, 0.05, 0.08)
const RECOIL_RETURN_SPEED = 14.0
const BODY_TURN_LERP = 0.15

@export_category("Objects")
@export var body_root: Node3D = null
@export var spring_arm_offset: Node3D = null
@export var spring_arm: SpringArm3D = null
@export var camera_node: Camera3D = null
@export var weapon_root: Node3D = null
@export var muzzle_marker: Marker3D = null

var _camera_pitch := 0.0
@onready var animation_player: AnimationPlayer = $UAL1_Standard/AnimationPlayer
var _projectile_scene := preload("res://simple_projectile.tscn")
var _one_shot_animation := ""
var _shoot_was_pressed := false
var _punch_was_pressed := false
var _is_aiming := false
var _was_on_floor := true
var _weapon_rest_position := Vector3.ZERO
var _weapon_rest_rotation := Vector3.ZERO
var _recoil_position_offset := Vector3.ZERO
var _recoil_rotation_offset := Vector3.ZERO

func _ready() -> void:
	if body_root == null:
		body_root = get_node_or_null("UAL1_Standard")
	if spring_arm_offset == null:
		spring_arm_offset = get_node_or_null("SpringArmOffset")
	if spring_arm == null:
		spring_arm = get_node_or_null("SpringArmOffset/SpringArm3D")
	if camera_node == null:
		camera_node = get_node_or_null("SpringArmOffset/SpringArm3D/Camera3D")
	if weapon_root == null:
		weapon_root = get_node_or_null("UAL1_Standard/Armature/Skeleton3D/RightHand/FAB converted")
	if muzzle_marker == null and weapon_root:
		muzzle_marker = weapon_root.get_node_or_null("Muzzle")
	if camera_node:
		_camera_pitch = spring_arm.rotation.x if spring_arm else camera_node.rotation.x
		camera_node.current = true
		camera_node.make_current()
	if weapon_root:
		_weapon_rest_position = weapon_root.position
		_weapon_rest_rotation = weapon_root.rotation
	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
		animation_player.play("Idle")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if spring_arm_offset:
			spring_arm_offset.rotate_y(-event.relative.x * MOUSE_SENSIBILITY)
		if spring_arm:
			_camera_pitch = clamp(_camera_pitch - event.relative.y * MOUSE_SENSIBILITY, MIN_PITCH, MAX_PITCH)
			spring_arm.rotation.x = _camera_pitch

func _process(delta: float) -> void:
	if weapon_root == null:
		return
	_recoil_position_offset = _recoil_position_offset.lerp(Vector3.ZERO, delta * RECOIL_RETURN_SPEED)
	_recoil_rotation_offset = _recoil_rotation_offset.lerp(Vector3.ZERO, delta * RECOIL_RETURN_SPEED)
	weapon_root.position = _weapon_rest_position + _recoil_position_offset
	weapon_root.rotation = _weapon_rest_rotation + _recoil_rotation_offset


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	_is_aiming = _is_aim_pressed()
	var is_crouching := Input.is_physical_key_pressed(KEY_CTRL)
	if _is_shoot_just_pressed():
		_play_one_shot("Pistol_Shoot")
		_fire_projectile()
		_apply_weapon_recoil()
	elif _is_punch_just_pressed():
		_play_one_shot("Punch_Jab")

	var input_direction := _get_move_input()
	var direction := Vector3(input_direction.x, 0.0, input_direction.y)
	var is_sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and not is_crouching
	var current_speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else SPEED)
	if direction.length() > 0.0:
		direction = direction.normalized()
		direction = (transform.basis * direction).normalized()
		if spring_arm_offset:
			direction = direction.rotated(Vector3.UP, spring_arm_offset.rotation.y)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		_apply_body_rotation(Vector3(velocity.x, 0.0, velocity.z))
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	var just_landed := not _was_on_floor and is_on_floor()
	_was_on_floor = is_on_floor()
	if just_landed:
		_play_one_shot("Jump_Land")
	_update_animation(is_crouching, is_sprinting)

func _update_animation(is_crouching: bool, is_sprinting: bool) -> void:
	if animation_player == null:
		return
	if _one_shot_animation != "":
		return
	var next_animation := "Idle"
	if not is_on_floor():
		next_animation = "Jump"
	elif is_crouching:
		next_animation = "Crouch_Fwd" if Vector2(velocity.x, velocity.z).length() > 0.1 else "Crouch_Idle"
	elif _is_aiming:
		next_animation = "Pistol_Aim_Neutral"
	elif Vector2(velocity.x, velocity.z).length() > 0.1:
		next_animation = "Sprint" if is_sprinting else "Walk"
	if animation_player.current_animation != next_animation:
		animation_player.play(next_animation)

func _is_aim_pressed() -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return true
	for device in Input.get_connected_joypads():
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > AIM_TRIGGER_THRESHOLD:
			return true
	return false

func _is_shoot_just_pressed() -> bool:
	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for device in Input.get_connected_joypads():
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD:
			is_pressed = true
			break
	var just_pressed := is_pressed and not _shoot_was_pressed
	_shoot_was_pressed = is_pressed
	return just_pressed

func _is_punch_just_pressed() -> bool:
	var is_pressed := Input.is_physical_key_pressed(KEY_F)
	var just_pressed := is_pressed and not _punch_was_pressed
	_punch_was_pressed = is_pressed
	return just_pressed

func _play_one_shot(animation_name: String) -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(animation_name):
		return
	if _one_shot_animation == animation_name and animation_player.is_playing():
		return
	_one_shot_animation = animation_name
	animation_player.play(animation_name)

func _on_animation_finished(animation_name: StringName) -> void:
	if String(animation_name) == _one_shot_animation:
		_one_shot_animation = ""

func _get_move_input() -> Vector2:
	var input_direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_direction.y += 1.0
	return input_direction.normalized() if input_direction.length_squared() > 1.0 else input_direction

func _apply_body_rotation(horizontal_velocity: Vector3) -> void:
	if body_root == null or horizontal_velocity.length_squared() <= 0.001:
		return
	var target_rotation := atan2(-horizontal_velocity.x, -horizontal_velocity.z)
	body_root.rotation.y = lerp_angle(body_root.rotation.y, target_rotation, BODY_TURN_LERP)

func _apply_weapon_recoil() -> void:
	if weapon_root == null:
		return
	_recoil_position_offset -= RECOIL_POSITION_KICK
	_recoil_rotation_offset += RECOIL_ROTATION_KICK

func _fire_projectile() -> void:
	if muzzle_marker == null or _projectile_scene == null:
		return
	var projectile := _projectile_scene.instantiate()
	if projectile == null:
		return
	projectile.name = "Bullet"
	projectile.global_position = muzzle_marker.global_position
	var direction := _get_projectile_direction(muzzle_marker.global_position)
	projectile.set("direction", direction)
	projectile.set("speed", PROJECTILE_SPEED)
	projectile.look_at(muzzle_marker.global_position + direction, Vector3.UP)
	get_tree().current_scene.add_child(projectile)

func _get_projectile_direction(origin: Vector3) -> Vector3:
	if camera_node == null:
		return -global_transform.basis.z
	var viewport := get_viewport()
	if viewport == null:
		return -camera_node.global_transform.basis.z
	var view_center := viewport.get_visible_rect().size * 0.5
	var ray_origin := camera_node.project_ray_origin(view_center)
	var ray_direction := camera_node.project_ray_normal(view_center)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * PROJECTILE_RANGE)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = ray_origin + ray_direction * PROJECTILE_RANGE
	if hit.has("position"):
		target = hit["position"]
	return (target - origin).normalized()
