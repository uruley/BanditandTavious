class_name PlayerSlide
extends PlayerState

@export var slide_duration := 0.65
@export var slide_start_speed := 10.5
@export var slide_end_speed := 3.0
@export var slide_deceleration := 13.0
@export var downhill_boost := 5.0

var _slide_direction := Vector3.ZERO
var _slide_speed := 0.0
var _timer := 0.0

func enter(msg := {}) -> void:
	_timer = float(msg.get("duration", slide_duration))
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	if horizontal_velocity.length_squared() > 0.01:
		_slide_direction = horizontal_velocity.normalized()
	else:
		_slide_direction = player.get_move_direction()
	if _slide_direction.length_squared() < 0.01:
		_slide_direction = -player.global_transform.basis.z
	_slide_direction.y = 0.0
	_slide_direction = _slide_direction.normalized()

	_slide_speed = max(slide_start_speed, horizontal_velocity.length())
	player.lock_state_animation(["parkour/Slide", "Slide", "Roll_RM", "Crouch_Fwd"], ["Crouch_Fwd", "Crouch_Idle"])

func exit() -> void:
	player.clear_state_animation_lock()

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Air")
		return

	_timer -= delta
	_slide_speed = move_toward(_slide_speed, slide_end_speed, slide_deceleration * delta)

	var floor_normal := player.get_floor_normal()
	if floor_normal != Vector3.ZERO and floor_normal.y < 0.98:
		var downhill := Vector3.DOWN.slide(floor_normal).normalized()
		_slide_direction = (_slide_direction + downhill * (downhill_boost * delta)).normalized()

	player.velocity.y += player.get_gravity().y * delta
	player.velocity.x = _slide_direction.x * _slide_speed
	player.velocity.z = _slide_direction.z * _slide_speed
	player.move_and_slide()

	if _timer <= 0.0:
		if player.get_move_direction().length_squared() > 0.01:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
