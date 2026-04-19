extends CPUParticles3D

func _ready():
	emitting = true
	# Wait for the particles to finish (lifetime + extra time for safety)
	await get_tree().create_timer(lifetime + 1.0).timeout
	queue_free()
