class_name PlayerWallRun
extends PlayerState

@export var wall_run_gravity := 2.0
@export var wall_run_speed := 7.0
@export var camera_tilt := 15.0

var wall_normal: Vector3
func enter(_msg := {}) -> void:
	print("DEBUG: Entered WallRun")
	wall_normal = player.get_wall_normal()
	player.get_wall_run_animation()
	
	# Initial boost if needed
	player.velocity.y = 0

func exit() -> void:
	# Reset camera tilt if we had one
	_set_camera_tilt(0)
	player.clear_state_animation_lock()

func physics_update(delta: float) -> void:
	if not player.is_on_wall_only() or player.is_on_floor():
		state_machine.transition_to("Air")
		return

	# Transition to jump if space pressed
	if Input.is_physical_key_pressed(KEY_SPACE):
		var jump_dir = (wall_normal + Vector3.UP).normalized()
		player.velocity = jump_dir * BachtaviousPlayer.JUMP_VELOCITY * 1.5
		state_machine.transition_to("Air")
		return

	wall_normal = player.get_wall_normal()
	
	# Project forward movement along the wall
	var input_dir = player.get_move_direction()
	var wall_tangent = input_dir.slide(wall_normal).normalized()
	
	if wall_tangent.length_squared() > 0.01:
		player.velocity.x = wall_tangent.x * wall_run_speed
		player.velocity.z = wall_tangent.z * wall_run_speed
	else:
		# If no input, slide down the wall
		player.velocity.x = move_toward(player.velocity.x, 0, delta * 10)
		player.velocity.z = move_toward(player.velocity.z, 0, delta * 10)
		
	# Apply reduced gravity
	player.velocity.y -= wall_run_gravity * delta
	
	player.move_and_slide()
	
	# Camera juice
	var side_dot = player.global_transform.basis.x.dot(wall_normal)
	_set_camera_tilt(-side_dot * camera_tilt)

func _set_camera_tilt(amount: float) -> void:
	if player.spring_arm:
		player.spring_arm.rotation_degrees.z = lerp(player.spring_arm.rotation_degrees.z, amount, 0.1)
