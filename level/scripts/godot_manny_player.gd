extends CharacterBody3D

const WALK_SPEED := 6.0
const SPRINT_SPEED := 10.0
const JUMP_VELOCITY := 10.0
const TURN_SPEED := 12.0

@export_category("Objects")
@export var _body: Node3D = null
@export var _spring_arm_offset: Node3D = null
@export var _spring_arm: SpringArm3D = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var animation_player: AnimationPlayer = null

func _enter_tree() -> void:
	var peer_id = str(name).to_int()
	if peer_id > 0:
		$SpringArmOffset/SpringArm3D/Camera3D.current = false

func _ready() -> void:
	floor_snap_length = 0.4
	animation_player = _body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_animation("Idle")
	if not await _configure_multiplayer_state():
		push_warning("Player spawned without a replicated peer id: %s" % name)

func _configure_multiplayer_state() -> bool:
	var cam = $SpringArmOffset/SpringArm3D/Camera3D
	var peer_id = str(name).to_int()
	if peer_id <= 0:
		cam.current = true
		cam.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return true
	for _attempt in 4:
		await get_tree().process_frame
		var local_peer_id = multiplayer.get_unique_id()
		if local_peer_id <= 0:
			continue
		set_multiplayer_authority(peer_id)
		cam.current = (peer_id == local_peer_id)
		if cam.current:
			cam.make_current()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return true
	cam.current = false
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	_move(delta)
	move_and_slide()
	_update_animation()

func _move(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	direction = direction.rotated(Vector3.UP, _spring_arm_offset.rotation.y)

	var speed := SPRINT_SPEED if Input.is_action_pressed("shift") else WALK_SPEED

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_angle := atan2(direction.x, direction.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, target_angle, TURN_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

func _update_animation() -> void:
	if animation_player == null:
		return
	var anim: String
	if not is_on_floor():
		anim = "Jump"
	elif velocity.length() < 0.1:
		anim = "Idle"
	elif Input.is_action_pressed("shift"):
		anim = "Sprint"
	else:
		anim = "Walk"
	_play_animation(anim)

func _play_animation(anim_name: String) -> void:
	if not animation_player.has_animation(anim_name):
		return
	if animation_player.current_animation == anim_name:
		return
	animation_player.play(anim_name, 0.15)
