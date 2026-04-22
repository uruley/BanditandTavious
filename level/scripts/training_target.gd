extends StaticBody3D

var hits: int = 0
var _mat: StandardMaterial3D
var _flash_timer: float = 0.0

const BASE_COLOR := Color(0.8, 0.15, 0.15, 1.0)
const HIT_COLOR := Color(1.0, 1.0, 0.1, 1.0)


func _ready() -> void:
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = BASE_COLOR
		_mat.roughness = 0.7
		mesh_inst.material_override = _mat


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _mat:
			_mat.albedo_color = BASE_COLOR


func register_hit() -> void:
	hits += 1
	_flash_timer = 0.12
	if _mat:
		_mat.albedo_color = HIT_COLOR


func reset() -> void:
	hits = 0
	if _mat:
		_mat.albedo_color = BASE_COLOR
