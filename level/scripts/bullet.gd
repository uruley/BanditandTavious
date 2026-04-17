extends CharacterBody3D

@export var speed: float = 40.0
@export var damage: int = 1
var shooter_id: int = 0

func _ready():
	# Auto-destroy after 2 seconds if it doesn't hit anything
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		# Ignore the person who shot this bullet
		if collider.name.is_valid_int():
			if collider.name.to_int() == shooter_id:
				return

		if collider.has_method("take_damage"):
			collider.take_damage(damage, shooter_id)
		queue_free()
