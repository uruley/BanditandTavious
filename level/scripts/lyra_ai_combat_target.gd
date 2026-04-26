extends StaticBody3D

@export var max_health: float = 10000.0
@export var label_text: String = "Combat Target"

var health: float = max_health
var hits: int = 0
var total_damage: float = 0.0
var _material: StandardMaterial3D
var _flash_timer: float = 0.0


func _ready() -> void:
	add_to_group("lyra_ai_combat_target")
	health = max_health
	_configure_material()


func _process(delta: float) -> void:
	if _flash_timer <= 0.0:
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0 and _material:
		_material.albedo_color = Color(0.85, 0.18, 0.18, 1.0)


func is_alive() -> bool:
	return health > 0.0


func take_damage(amount: float, _source: Node = null) -> void:
	var applied_damage := maxf(amount, 0.0)
	health = maxf(0.0, health - applied_damage)
	hits += 1
	total_damage += applied_damage
	_flash_timer = 0.12
	if _material:
		_material.albedo_color = Color(1.0, 0.95, 0.2, 1.0)


func reset() -> void:
	health = max_health
	hits = 0
	total_damage = 0.0
	if _material:
		_material.albedo_color = Color(0.85, 0.18, 0.18, 1.0)


func _configure_material() -> void:
	var mesh_instance := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance == null:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.85, 0.18, 0.18, 1.0)
	_material.roughness = 0.75
	mesh_instance.material_override = _material
