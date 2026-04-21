extends CharacterBody3D

const WALK_SPEED := 22.0
const SPRINT_SPEED := 36.0
const JUMP_VELOCITY := 12.0
const MOUSE_SENSITIVITY := 0.003
const PITCH_MIN := deg_to_rad(-65.0)
const PITCH_MAX := deg_to_rad(45.0)

@export var planet_center: Vector3 = Vector3.ZERO
@export var spawn_height: float = 152.0

@onready var spring_arm: SpringArm3D = $SpringArmOffset/SpringArm3D
@onready var camera: Camera3D = $SpringArmOffset/SpringArm3D/Camera3D
@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	if global_position.length() < 0.01:
		global_position = Vector3(0.0, spawn_height, 0.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	floor_snap_length = 3.0
	_align_to_surface(_get_surface_up(), Vector3.FORWARD)
	_play_animation("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var surface_up := _get_surface_up()
		global_basis = Basis(surface_up, -event.relative.x * MOUSE_SENSITIVITY) * global_basis
		spring_arm.rotation.x = clamp(
			spring_arm.rotation.x - event.relative.y * MOUSE_SENSITIVITY,
			PITCH_MIN,
			PITCH_MAX
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	var surface_up := _get_surface_up()
	up_direction = surface_up

	if not is_on_floor():
		velocity += -surface_up * gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity += surface_up * JUMP_VELOCITY

	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_right := global_basis.x.slide(surface_up).normalized()
	var move_forward := (-global_basis.z).slide(surface_up).normalized()
	var move_direction := (move_right * input_direction.x + move_forward * input_direction.y).normalized()
	var speed := SPRINT_SPEED if Input.is_action_pressed("shift") else WALK_SPEED

	var radial_velocity := surface_up * velocity.dot(surface_up)
	var tangential_velocity := velocity - radial_velocity

	if move_direction != Vector3.ZERO:
		tangential_velocity = move_direction * speed
		_align_to_surface(surface_up, move_direction)
	else:
		tangential_velocity = tangential_velocity.move_toward(Vector3.ZERO, speed * delta * 4.0)
		_align_to_surface(surface_up, (-global_basis.z).slide(surface_up).normalized())

	velocity = tangential_velocity + radial_velocity
	move_and_slide()
	_update_animation(move_direction, speed)


func _get_surface_up() -> Vector3:
	var from_center := global_position - planet_center
	if from_center.length_squared() < 0.001:
		return Vector3.UP
	return from_center.normalized()


func _align_to_surface(surface_up: Vector3, forward_hint: Vector3) -> void:
	var forward := forward_hint
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD.slide(surface_up)
		if forward.length_squared() < 0.001:
			forward = Vector3.RIGHT.slide(surface_up)
	forward = forward.normalized()
	var right := forward.cross(surface_up).normalized()
	global_basis = Basis(right, surface_up, -forward).orthonormalized()


func _update_animation(move_direction: Vector3, speed: float) -> void:
	if not is_on_floor():
		_play_animation("Jump")
		return
	if move_direction == Vector3.ZERO:
		_play_animation("Idle")
		return
	if speed == SPRINT_SPEED:
		_play_animation("Sprint")
	else:
		_play_animation("Walk")


func _play_animation(name: String) -> void:
	if not animation_player.has_animation(name):
		return
	if animation_player.current_animation == name:
		return
	animation_player.play(name, 0.15)
