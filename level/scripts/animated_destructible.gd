extends StaticBody3D

@export var health: float = 5.0
@export var animation_player_path: NodePath = "fractured_large_cube/AnimationPlayer"

var is_destroyed := false
@onready var anim_player: AnimationPlayer = get_node(animation_player_path)
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func take_damage(amount: float, _from_id: int = 0):
	if is_destroyed: return
	health -= amount
	print("!!! Large Cube took ", amount, " damage. Health: ", health)
	if health <= 0:
		destroy()

func destroy(_impulse_direction: Vector3 = Vector3.ZERO):
	if is_destroyed: return
	is_destroyed = true
	
	# Disable collision so bullets pass through shards
	collision_shape.disabled = true
	
	if anim_player:
		# The default Blender action is usually called "Action" or "LargeFracturedAction"
		# Let's try to find the first available animation if "Action" fails
		var anim_name = "Action"
		if not anim_player.has_animation(anim_name):
			var anims = anim_player.get_animation_list()
			if anims.size() > 0:
				anim_name = anims[0]
		
		anim_player.play(anim_name)
		print("!!! Playing destruction animation: ", anim_name)
		
		# Auto-cleanup after animation
		await anim_player.animation_finished
		await get_tree().create_timer(5.0).timeout
		queue_free()
	else:
		print("!!! ERROR: AnimationPlayer not found for Large Cube")
		queue_free()
