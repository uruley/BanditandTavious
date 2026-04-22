extends Area3D

## The path to the portal this one is linked to.
@export var linked_portal_path: NodePath

## The actual portal instance (resolved from path).
var linked_portal: Area3D

## Offset to prevent infinite teleport loops.
@export var exit_offset: float = 2.0

## Cooldown to prevent infinite loops.
var _is_on_cooldown: bool = false

# Track tracking bodies to detect crossing
var _tracked_bodies = {}

func _ready() -> void:
	# Resolve the portal reference if a path was provided
	if linked_portal_path:
		linked_portal = get_node_or_null(linked_portal_path)
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		# Start tracking this body's position relative to the plane
		_tracked_bodies[body] = _is_front(body.global_position)

func _on_body_exited(body: Node3D) -> void:
	_tracked_bodies.erase(body)

func _physics_process(_delta: float) -> void:
	if _is_on_cooldown: return
	
	# Create a list of keys to avoid modification during iteration
	var bodies = _tracked_bodies.keys()
	for body in bodies:
		if not is_instance_valid(body):
			_tracked_bodies.erase(body)
			continue
			
		var current_front = _is_front(body.global_position)
		var was_front = _tracked_bodies[body]
		
		# --- Crossing Detection ---
		# If they were in front and are now behind, they crossed the threshold!
		if was_front and not current_front:
			if linked_portal == null and linked_portal_path:
				linked_portal = get_node_or_null(linked_portal_path)
				
			if linked_portal:
				teleport_body(body)
				return 
		
		_tracked_bodies[body] = current_front

func _is_front(pos: Vector3) -> bool:
	# A point is in 'front' if the dot product of (point - portal_pos) and portal_forward is positive.
	# In Godot, -Z is forward.
	var portal_forward = -global_transform.basis.z
	var rel_pos = pos - global_position
	return rel_pos.dot(portal_forward) > 0

func teleport_body(body: CharacterBody3D) -> void:
	# Clear tracking
	_tracked_bodies.erase(body)
	
	# Start cooldown on BOTH portals
	_start_cooldown()
	if linked_portal:
		linked_portal._start_cooldown()

	# 1. Transform math for seamless transition
	# Calculate how the player is oriented relative to the entrance portal
	var relative_to_entrance = global_transform.affine_inverse() * body.global_transform
	
	# Map that same relative orientation to the exit portal
	# We removed the 180 flip because entering "Face In" naturally leads to exiting "Face Out"
	var final_transform = linked_portal.global_transform * relative_to_entrance
	
	# 2. Add forward boost along the NEW facing direction to clear the collision
	# In Godot, -Z is forward. We move along the character's new -Z axis.
	var forward_vector = -final_transform.basis.z
	final_transform.origin += forward_vector * exit_offset

	# 3. Preserve momentum by rotating the velocity vector
	# Relative rotation = ExitBasis * EntranceBasis.Inverse
	var relative_rotation = linked_portal.global_transform.basis * global_transform.basis.inverse()
	var final_velocity = relative_rotation * body.velocity
	
	# 4. Apply changes DEFERRED
	body.set_deferred("global_transform", final_transform)
	body.set_deferred("velocity", final_velocity)
	
	# 5. Reset physics interpolation (mandatory for Godot 4.4+)
	if body.has_method("reset_physics_interpolation"):
		body.call_deferred("reset_physics_interpolation")
	
	print("Seamless Face-Away Teleport: ", body.name)

func _start_cooldown() -> void:
	_is_on_cooldown = true
	get_tree().create_timer(0.2).timeout.connect(func(): _is_on_cooldown = false)
