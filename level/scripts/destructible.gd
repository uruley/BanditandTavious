extends RigidBody3D

@export var fractured_scene: PackedScene
@export var shard_impulse: float = 2.0
@export var cleanup_time: float = 10.0
@export var impact_threshold: float = 2.0
@export var health: float = 3.0
@export var mass_resistance: float = 2.0
@export var invulnerability_time: float = 0.5

var last_velocity: Vector3 = Vector3.ZERO
var is_destroyed = false
var spawn_time: float = 0.0

func _ready():
	print("!!! DESTRUCTIBLE SYSTEM ONLINE: ", name)
	spawn_time = Time.get_ticks_msec() / 1000.0
	# Ensure physics is listening
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)

func _is_invulnerable() -> bool:
	return (Time.get_ticks_msec() / 1000.0) - spawn_time < invulnerability_time

func _integrate_forces(state):
	# Crucial: Jolt velocity can zero out on the frame of impact,
	# so we store the velocity from the frame BEFORE impact.
	var current_vel = state.linear_velocity
	if current_vel.length() > 0.1:
		last_velocity = current_vel

func _physics_process(delta):
	if is_destroyed or _is_invulnerable(): return
	
	# METHOD 1: Direct Contact Check (Best for Jolt)
	var bodies = get_colliding_bodies()
	if bodies.size() > 0:
		check_and_destroy(last_velocity.length())
		return

	# METHOD 2: Predictive Raycast (Prevents falling through floor)
	var space_state = get_world_3d().direct_space_state
	# Cast a ray slightly further than we travel this frame
	var prediction = linear_velocity * delta * 2.0 
	if prediction.length() < 0.2: prediction = Vector3.DOWN * 0.2
	
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + prediction)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	if result:
		check_and_destroy(last_velocity.length())

func _on_body_entered(_body):
	# METHOD 3: Standard Signal
	if is_destroyed or _is_invulnerable(): return
	check_and_destroy(last_velocity.length())

func check_and_destroy(speed: float):
	if speed >= impact_threshold:
		destroy()

func destroy(impulse_direction: Vector3 = Vector3.ZERO):
	if is_destroyed: return
	is_destroyed = true
	
	if not fractured_scene:
		print("!!! ERROR: No shards assigned to ", name)
		queue_free()
		return
		
	var shards = fractured_scene.instantiate()
	shards.add_to_group("shards")
	for child in shards.get_children():
		if child is Node:
			child.add_to_group("shards")

	# Add to level root so shards don't move with the (soon to be deleted) box
	get_parent().add_child(shards)
	shards.global_transform = global_transform
	# ENSURE SCALE IS PRESERVED
	shards.scale = scale
	
	for child in shards.get_children():
		if child is RigidBody3D:
			# Shards inherit the speed the box had
			child.linear_velocity = last_velocity
			
			# Add extra randomized "explosion" pop
			var dir = impulse_direction
			if dir == Vector3.ZERO:
				dir = Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized()
			child.apply_central_impulse(dir * shard_impulse)
			
			if cleanup_time > 0:
				var timer = get_tree().create_timer(cleanup_time + randf_range(0, 2))
				timer.timeout.connect(func(): if is_instance_valid(child): child.queue_free())
	
	print("!!! DESTRUCTION COMPLETE")
	queue_free()

func take_damage(amount: float, _from_id: int = 0):
	if is_destroyed: return
	health -= amount
	print("!!! ", name, " took ", amount, " damage. Health: ", health)
	if health <= 0:
		destroy()
