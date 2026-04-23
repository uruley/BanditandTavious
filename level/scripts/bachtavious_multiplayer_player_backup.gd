extends CharacterBody3D

const SPEED := 5.0
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSIBILITY := 0.005
const MIN_PITCH := -PI / 4.0
const MAX_PITCH := PI / 6.0
const TRIGGER_THRESHOLD := 0.5
const AIM_TRIGGER_THRESHOLD := 0.5
const CROUCH_SPEED := 2.5
const PROJECTILE_SPEED := 45.0
const PROJECTILE_RANGE := 200.0
const RECOIL_POSITION_KICK := Vector3(0.0, 0.015, 0.08)
const RECOIL_ROTATION_KICK := Vector3(-0.16, 0.05, 0.08)
const RECOIL_RETURN_SPEED := 14.0
const AIM_BODY_TURN_LERP := 0.25
const DEFAULT_FOV := 75.0
const ADS_FOV := 50.0
const DEFAULT_SPRING_LENGTH := 2.5
const ADS_SPRING_LENGTH := 1.5
const DEFAULT_H_OFFSET := 0.0
const ADS_H_OFFSET := 0.15

@onready var nickname: Label3D = $PlayerNick/Nickname
@onready var chat_label: Label3D = $PlayerChat/Text

@export_category("Objects")
@export var body_root: Node3D = null
@export var spring_arm_offset: Node3D = null
@export var spring_arm: SpringArm3D = null
@export var camera_node: Camera3D = null
@export var weapon_root: Node3D = null
@export var muzzle_marker: Marker3D = null
@export var forward_ray: RayCast3D = null
@export var head_ray: RayCast3D = null
@export var ledge_ray: RayCast3D = null

var _respawn_point := Vector3(0, 5, 0)
var _camera_pitch := 0.0
var _camera_tween: Tween
var _parkour_tween: Tween
var _projectile_scene := preload("res://simple_projectile.tscn")
var _one_shot_animation := ""
var _shoot_was_pressed := false
var _punch_was_pressed := false
var _is_aiming := false
var _is_parkouring := false
var _was_on_floor := true
var _weapon_rest_position := Vector3.ZERO
var _weapon_rest_rotation := Vector3.ZERO
var _recoil_position_offset := Vector3.ZERO
var _recoil_rotation_offset := Vector3.ZERO
var _body_rest_rotation_y := 0.0
var _animation_player: AnimationPlayer = null

func _enter_tree() -> void:
	var local_camera := get_node_or_null("SpringArmOffset/SpringArm3D/Camera3D") as Camera3D
	if local_camera:
		local_camera.current = false

func _ready() -> void:
	_resolve_nodes()
	_disable_preview_nodes()
	_consolidate_libraries()

	if camera_node:
		_camera_pitch = spring_arm.rotation.x if spring_arm else camera_node.rotation.x
		camera_node.current = false
		camera_node.fov = DEFAULT_FOV
		camera_node.h_offset = DEFAULT_H_OFFSET
	if spring_arm:
		spring_arm.spring_length = DEFAULT_SPRING_LENGTH
	if weapon_root:
		_weapon_rest_position = weapon_root.position
		_weapon_rest_rotation = weapon_root.rotation
	if body_root:
		_body_rest_rotation_y = body_root.rotation.y
	chat_label.hide()

	if not await _configure_multiplayer_state():
		push_warning("Player spawned without a replicated peer id: %s" % name)
		return

func _resolve_nodes() -> void:
	if body_root == null:
		body_root = get_node_or_null("Bachtavious")
	if spring_arm_offset == null:
		spring_arm_offset = get_node_or_null("SpringArmOffset")
	if spring_arm == null:
		spring_arm = get_node_or_null("SpringArmOffset/SpringArm3D")
	if camera_node == null:
		camera_node = get_node_or_null("SpringArmOffset/SpringArm3D/Camera3D")
	if weapon_root == null:
		weapon_root = get_node_or_null("Bachtavious/Armature/Skeleton3D/RightHand/FAB converted")
	if muzzle_marker == null:
		muzzle_marker = get_node_or_null("Bachtavious/Armature/Skeleton3D/RightHand/FAB converted/Muzzle")
	if forward_ray == null:
		forward_ray = get_node_or_null("Scanner/ForwardRay")
	if head_ray == null:
		head_ray = get_node_or_null("Scanner/HeadRay")
	if ledge_ray == null:
		ledge_ray = get_node_or_null("Scanner/LedgeRay")
	if _animation_player == null:
		_animation_player = get_node_or_null("Bachtavious/AnimationPlayer") as AnimationPlayer

func _disable_preview_nodes() -> void:
	if Engine.is_editor_hint():
		return
	for node_path in ["Bachtavious/WorldEnvironment", "Bachtavious/DirectionalLight3D", "Bachtavious/Camera3D"]:
		var node := get_node_or_null(node_path)
		if node:
			node.queue_free()

func _configure_multiplayer_state() -> bool:
	for _attempt in 4:
		await get_tree().process_frame
		var peer_id := str(name).to_int()
		var local_peer_id := multiplayer.get_unique_id()
		if peer_id <= 0 or local_peer_id <= 0:
			continue
		set_multiplayer_authority(peer_id)
		var is_local_player := peer_id == local_peer_id
		if camera_node:
			camera_node.current = is_local_player
			if is_local_player:
				camera_node.make_current()
		if is_local_player:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return true
	if camera_node:
		camera_node.current = false
	return false

func _consolidate_libraries() -> void:
	if _animation_player == null:
		_animation_player = get_node_or_null("Bachtavious/AnimationPlayer") as AnimationPlayer
		if _animation_player == null:
			return
	if body_root == null:
		body_root = get_node_or_null("Bachtavious")
	if body_root:
		_animation_player.root_node = _animation_player.get_path_to(body_root)

	if not _animation_player.has_animation_library("parkour"):
		var parkour_lib_path := "res://assets/animations/parkour_pro.res"
		if FileAccess.file_exists(parkour_lib_path):
			var parkour_lib = load(parkour_lib_path)
			if parkour_lib:
				_animation_player.add_animation_library("parkour", parkour_lib)

	if not _animation_player.has_animation_library("locomotion"):
		var locomotion_lib_path := "res://assets/animations/locomotion_base.res"
		if FileAccess.file_exists(locomotion_lib_path):
			var locomotion_lib = load(locomotion_lib_path)
			if locomotion_lib:
				_animation_player.add_animation_library("locomotion", locomotion_lib)

	if not _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_finished)

	if not _animation_player.is_playing() and _animation_player.has_animation("Idle"):
		_animation_player.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSIBILITY)
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
	if body_root and _is_aiming and spring_arm_offset:
		body_root.global_rotation.y = lerp_angle(body_root.global_rotation.y, spring_arm_offset.global_rotation.y, AIM_BODY_TURN_LERP)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var current_scene := get_tree().get_current_scene()
	if current_scene and current_scene.has_method("is_chat_visible") and current_scene.is_chat_visible() and is_on_floor():
		freeze()
		return

	if _is_parkouring:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		if not _check_parkour():
			velocity.y = JUMP_VELOCITY

	var was_aiming := _is_aiming
	_is_aiming = _is_aim_pressed()
	if was_aiming != _is_aiming:
		_toggle_ads(_is_aiming)

	var is_crouching := Input.is_physical_key_pressed(KEY_CTRL)
	if _is_shoot_just_pressed():
		_play_one_shot("Pistol_Shoot")
		_fire_projectile()
		_apply_weapon_recoil()
	elif _is_punch_just_pressed():
		_play_one_shot("Punch_Jab")

	var input_direction := _get_move_input()
	var direction := Vector3.ZERO
	var is_sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and not is_crouching
	var current_speed := CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_sprinting else SPEED)
	if input_direction.length() > 0.0:
		var forward := -spring_arm_offset.global_transform.basis.z if spring_arm_offset else -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := spring_arm_offset.global_transform.basis.x if spring_arm_offset else global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		direction = (right * input_direction.x) + (forward * -input_direction.y)
		direction = direction.normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()

	if is_on_floor() and input_direction.length() > 0.1:
		var space_state = get_world_3d().direct_space_state
		var step_query_pos = global_position + (direction * 0.4) + Vector3(0, 0.5, 0)
		var query = PhysicsRayQueryParameters3D.create(step_query_pos, step_query_pos + Vector3(0, -0.6, 0))
		query.collision_mask = 2
		var result = space_state.intersect_ray(query)
		if result:
			var step_height = result.position.y - global_position.y
			if step_height > 0.02 and step_height < 0.45:
				global_position.y = lerp(global_position.y, result.position.y, delta * 15.0)

	var just_landed := not _was_on_floor and is_on_floor()
	_was_on_floor = is_on_floor()
	if just_landed:
		_play_one_shot("Jump_Land")
	_check_fall_and_respawn()
	_update_animation(is_crouching, is_sprinting)

func freeze() -> void:
	velocity = Vector3.ZERO
	_update_animation(false, false)

func _check_fall_and_respawn() -> void:
	if global_position.y < -15.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO

func _update_animation(is_crouching: bool, is_sprinting: bool) -> void:
	if _animation_player == null:
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
	if _animation_player.current_animation != next_animation and _animation_player.has_animation(next_animation):
		_animation_player.play(next_animation)

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
	if _animation_player == null:
		return
	if not _animation_player.has_animation(animation_name):
		return
	if _one_shot_animation == animation_name and _animation_player.is_playing():
		return
	_one_shot_animation = animation_name
	_animation_player.play(animation_name)

func _on_animation_finished(animation_name: StringName) -> void:
	if String(animation_name) == _one_shot_animation:
		_one_shot_animation = ""

func _check_parkour() -> bool:
	if forward_ray == null or head_ray == null or ledge_ray == null:
		return false
	if not forward_ray.is_colliding():
		return false
	if not head_ray.is_colliding():
		var wall_pos = forward_ray.get_collision_point()
		ledge_ray.global_position = wall_pos + (-global_transform.basis.z * 0.5) + Vector3(0, 1.0, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var target_pos = ledge_ray.get_collision_point()
			_do_parkour_move(target_pos, "parkour/ClimbUp_1m_RM")
			return true
	elif head_ray.is_colliding():
		ledge_ray.global_position = global_position + (-global_transform.basis.z * 0.8) + Vector3(0, 3.0, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var mantle_target = ledge_ray.get_collision_point()
			_do_parkour_move(mantle_target, "parkour/NinjaJump_Start")
			return true
	return false

func _do_parkour_move(target_pos: Vector3, animation_name: String) -> void:
	_is_parkouring = true
	if _parkour_tween:
		_parkour_tween.kill()
	_parkour_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	var final_pos = target_pos + Vector3(0, 0.05, 0)
	_parkour_tween.tween_property(self, "global_position", final_pos, 0.8)
	_play_one_shot(animation_name)
	_parkour_tween.finished.connect(func():
		_is_parkouring = false
	)

func _toggle_ads(aiming: bool) -> void:
	if camera_node == null or spring_arm == null:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if aiming:
		_camera_tween.tween_property(camera_node, "fov", ADS_FOV, 0.2)
		_camera_tween.tween_property(spring_arm, "spring_length", ADS_SPRING_LENGTH, 0.2)
		_camera_tween.tween_property(camera_node, "h_offset", ADS_H_OFFSET, 0.2)
	else:
		_camera_tween.tween_property(camera_node, "fov", DEFAULT_FOV, 0.2)
		_camera_tween.tween_property(spring_arm, "spring_length", DEFAULT_SPRING_LENGTH, 0.2)
		_camera_tween.tween_property(camera_node, "h_offset", DEFAULT_H_OFFSET, 0.2)

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

func _apply_weapon_recoil() -> void:
	if weapon_root == null:
		return
	_recoil_position_offset -= RECOIL_POSITION_KICK
	_recoil_rotation_offset += RECOIL_ROTATION_KICK

func _fire_projectile() -> void:
	if muzzle_marker == null:
		return
	var direction := _get_projectile_direction(muzzle_marker.global_position)
	spawn_projectile.rpc(muzzle_marker.global_position, direction)

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

@rpc("any_peer", "call_local")
func spawn_projectile(pos: Vector3, dir: Vector3) -> void:
	if _projectile_scene == null:
		return
	var projectile = _projectile_scene.instantiate()
	if projectile == null:
		return
	projectile.name = "Bullet"
	projectile.global_position = pos
	projectile.set("direction", dir)
	projectile.set("speed", PROJECTILE_SPEED)
	projectile.look_at(pos + dir, Vector3.UP)
	get_tree().current_scene.add_child(projectile)

func is_running() -> bool:
	return Input.is_physical_key_pressed(KEY_SHIFT)

@rpc("any_peer", "reliable")
func change_nick(new_nick: String) -> void:
	if nickname:
		nickname.text = new_nick

func set_player_skin(_skin_name: String) -> void:
	pass

@rpc("any_peer", "reliable")
func display_chat_message(message: String) -> void:
	chat_label.text = message
	chat_label.show()
	await get_tree().create_timer(10.0).timeout
	chat_label.hide()
