class_name PlayerRun
extends PlayerState

func enter(_msg := {}) -> void:
	print("DEBUG: Entered Run")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Air")
		return

	if Input.is_physical_key_pressed(KEY_SPACE):
		var vault_data := player.find_vault_target()
		if vault_data.is_empty():
			state_machine.transition_to("Air", {"do_jump": true})
		else:
			state_machine.transition_to("Vault", vault_data)
		return

	var direction = player.get_move_direction()
	
	if direction.length_squared() < 0.01:
		state_machine.transition_to("Idle")
		return
		
	var is_crouching := Input.is_physical_key_pressed(KEY_CTRL)
	var is_sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and not is_crouching
	var current_speed := BachtaviousPlayer.CROUCH_SPEED if is_crouching else (BachtaviousPlayer.SPRINT_SPEED if is_sprinting else BachtaviousPlayer.SPEED)

	if is_crouching and Vector2(player.velocity.x, player.velocity.z).length() > BachtaviousPlayer.CROUCH_SPEED + 0.5:
		state_machine.transition_to("Slide")
		return
	
	player.velocity.x = direction.x * current_speed
	player.velocity.z = direction.z * current_speed

	player.move_and_slide()
	
	if direction.length() > 0.1:
		var space_state = player.get_world_3d().direct_space_state
		var step_query_pos = player.global_position + (direction * 0.4) + Vector3(0, 0.5, 0)
		var query = PhysicsRayQueryParameters3D.create(step_query_pos, step_query_pos + Vector3(0, -0.6, 0))
		query.collision_mask = 2
		var result = space_state.intersect_ray(query)
		if result:
			var step_height = result.position.y - player.global_position.y
			if step_height > 0.02 and step_height < 0.45:
				player.global_position.y = lerp(player.global_position.y, result.position.y, delta * 15.0)

	if player.has_method("animate_body"):
		player.animate_body(player.velocity)
	if player.has_method("rotate_body"):
		player.rotate_body(player.velocity)
