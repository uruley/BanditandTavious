class_name PlayerAir
extends PlayerState

func enter(msg := {}) -> void:
	print("DEBUG: Entered Air")
	if msg.has("do_jump"):
		player.velocity.y = BachtaviousPlayer.JUMP_VELOCITY

func physics_update(delta: float) -> void:
	# Apply gravity
	player.velocity += player.get_gravity() * delta

	var direction = player.get_move_direction()
	
	if direction != Vector3.ZERO:
		player.velocity.x = direction.x * BachtaviousPlayer.SPEED
		player.velocity.z = direction.z * BachtaviousPlayer.SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, BachtaviousPlayer.SPEED)
		player.velocity.z = move_toward(player.velocity.z, 0, BachtaviousPlayer.SPEED)
		
	player.move_and_slide()
	
	if player.is_on_wall_only() and player.get_move_direction().length_squared() > 0.1:
		state_machine.transition_to("WallRun")
		return
	
	if player.has_method("animate_body"):
		player.animate_body(player.velocity)

	# Transition back to floor states
	if player.is_on_floor():
		if direction.length_squared() > 0.01:
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
