extends CharacterBody3D

@export var speed: float = 40.0
@export var damage: int = 1
var shooter_id: int = 0

var water_explosion_scene = preload("res://level/scenes/water_explosion.tscn")

func _ready():
	# Auto-destroy after 2 seconds if it doesn't hit anything
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta):
	var travel = velocity * delta
	
	# Raycast forward to prevent high-speed tunneling
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + travel * 1.5)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	
	var ray_result = space_state.intersect_ray(query)
	var collider = null
	var collision_pos = Vector3.ZERO
	
	if ray_result:
		collider = ray_result.collider
		collision_pos = ray_result.position
	else:
		var collision = move_and_collide(travel)
		if collision:
			collider = collision.get_collider()
			collision_pos = collision.get_position()

	if collider:
		# Ignore shooter
		if collider.name.is_valid_int() and collider.name.to_int() == shooter_id:
			return

		# Instantiate water explosion
		var explosion = water_explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = collision_pos

		if collider.has_method("take_damage"):
			collider.take_damage(damage, shooter_id)
		
		# If it's a destructible object, tell it WHICH way to explode
		if collider.has_method("destroy"):
			collider.destroy(velocity.normalized())
			
		queue_free()
