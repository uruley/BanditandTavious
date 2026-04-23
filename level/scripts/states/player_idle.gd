class_name PlayerIdle
extends PlayerState

func enter(_msg := {}) -> void:
	print("DEBUG: Entered Idle")
	player.velocity = Vector3.ZERO
	if player.has_method("animate_body"):
		player.animate_body(Vector3.ZERO)

func physics_update(_delta: float) -> void:
	player.velocity += player.get_gravity() * _delta
	player.move_and_slide()

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
	if direction.length_squared() > 0.01:
		state_machine.transition_to("Run")
