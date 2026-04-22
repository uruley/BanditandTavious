extends Area3D

var collected: bool = false
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = get_node_or_null("MeshInstance3D")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if body.has_method("collect_pickup"):
		body.collect_pickup()
		collected = true
		if _mesh:
			_mesh.visible = false


func reset() -> void:
	collected = false
	if _mesh:
		_mesh.visible = true
