extends CSGSphere3D

@export var orbit_radius: float = 3.0
@export var orbit_speed: float = 2.0
@export var orbit_height: float = 2.0
@export var color_speed: float = 1.0

var time: float = 0.0
var material_instance: StandardMaterial3D
@onready var particles: CPUParticles3D = get_node_or_null("Sparks")

func _ready():
	# Create a material for the sphere if it doesn't have one
	material_instance = StandardMaterial3D.new()
	self.material = material_instance
	
	# Force particles to start emitting
	if particles:
		particles.emitting = true
		particles.amount = 30 # Ensure enough particles
		print("DEBUG: Sparks particles found and emitting")
	else:
		print("DEBUG: Sparks node NOT found under ", name)

func _process(delta):
	time += delta
	
	# Orbit Logic
	var x = cos(time * orbit_speed) * orbit_radius
	var z = sin(time * orbit_speed) * orbit_radius
	
	# Update position (relative to parent tree)
	position = Vector3(x, orbit_height, z)
	
	# Color Changing Logic (Rainbow cycle)
	var hue = fmod(time * color_speed * 0.1, 1.0)
	var current_color = Color.from_hsv(hue, 0.8, 1.0)
	
	material_instance.albedo_color = current_color
	
	# Make particles match the ball color
	if particles:
		particles.color = current_color
