extends Node3D

@export var required_resources: int = 2
@export var capacity: int = 2
@export var label_text: String = ""
@export var foundation_color: Color = Color(0.35, 0.65, 1.0, 0.42)
@export var completed_color: Color = Color(0.72, 0.42, 0.16, 1.0)
@export var marker_size: Vector3 = Vector3(2.8, 0.12, 0.9)

var delivered_resources: int = 0
var is_complete: bool = false
var reserved_by: Array[String] = []

var _foundation_mesh: MeshInstance3D
var _complete_body: StaticBody3D
var _complete_collision: CollisionShape3D
var _label: Label3D


func _ready() -> void:
	add_to_group("lyra_ai_build_site")
	_configure_visuals()
	_refresh_visuals()


func can_reserve(actor_id: String) -> bool:
	return needs_resources() and (reserved_by.has(actor_id) or reserved_by.size() < max(1, capacity))


func reserve(actor_id: String) -> bool:
	if not can_reserve(actor_id):
		return false
	if not reserved_by.has(actor_id):
		reserved_by.append(actor_id)
	return true


func release(actor_id: String) -> void:
	reserved_by.erase(actor_id)


func needs_resources() -> bool:
	return not is_complete and delivered_resources < max(1, required_resources)


func receive_resource(amount: int = 1, actor: Node = null) -> Dictionary:
	if is_complete:
		return _build_result("already_complete", actor)

	var safe_amount: int = max(0, amount)
	if safe_amount <= 0:
		return _build_result("no_resource", actor)

	delivered_resources = min(max(1, required_resources), delivered_resources + safe_amount)
	if delivered_resources >= max(1, required_resources):
		is_complete = true
	_refresh_visuals()

	return _build_result("completed" if is_complete else "delivered", actor)


func is_build_complete() -> bool:
	return is_complete


func _configure_visuals() -> void:
	_foundation_mesh = get_node_or_null("FoundationMesh") as MeshInstance3D
	if _foundation_mesh == null:
		_foundation_mesh = MeshInstance3D.new()
		_foundation_mesh.name = "FoundationMesh"
		add_child(_foundation_mesh)
	var foundation_box := BoxMesh.new()
	foundation_box.size = marker_size
	_foundation_mesh.mesh = foundation_box
	_foundation_mesh.position = Vector3(0.0, marker_size.y * 0.5, 0.0)
	_foundation_mesh.material_override = _make_material(foundation_color, true)

	_complete_body = get_node_or_null("CompleteBody") as StaticBody3D
	if _complete_body == null:
		_complete_body = StaticBody3D.new()
		_complete_body.name = "CompleteBody"
		add_child(_complete_body)
		_add_plank("PlankLow", Vector3(0.0, 0.28, -0.18), 0.0)
		_add_plank("PlankMid", Vector3(0.0, 0.55, 0.08), 0.04)
		_add_plank("PlankHigh", Vector3(0.0, 0.82, -0.08), -0.04)
	_complete_collision = _complete_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _complete_collision == null:
		_complete_collision = CollisionShape3D.new()
		_complete_collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(marker_size.x, 0.9, marker_size.z * 0.65)
		_complete_collision.shape = shape
		_complete_collision.position = Vector3(0.0, 0.55, 0.0)
		_complete_body.add_child(_complete_collision)

	_label = get_node_or_null("Label3D") as Label3D
	if _label == null:
		_label = Label3D.new()
		_label.name = "Label3D"
		_label.position = Vector3(0.0, 1.45, 0.0)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.no_depth_test = true
		add_child(_label)


func _add_plank(plank_name: String, plank_position: Vector3, tilt: float) -> void:
	var plank := MeshInstance3D.new()
	plank.name = plank_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(marker_size.x, 0.18, 0.22)
	plank.mesh = mesh
	plank.position = plank_position
	plank.rotation.z = tilt
	plank.material_override = _make_material(completed_color, false)
	_complete_body.add_child(plank)


func _refresh_visuals() -> void:
	var ratio := float(delivered_resources) / float(max(1, required_resources))
	var foundation_mesh := _foundation_mesh.mesh as BoxMesh
	if foundation_mesh != null:
		foundation_mesh.size = Vector3(marker_size.x, marker_size.y, lerpf(marker_size.z * 0.35, marker_size.z, ratio))
	_foundation_mesh.visible = not is_complete
	_complete_body.visible = is_complete
	if _complete_collision != null:
		_complete_collision.disabled = not is_complete
	if _label != null:
		var display_name: String = label_text if label_text != "" else name
		_label.text = "%s\n%d/%d" % [display_name, delivered_resources, max(1, required_resources)]


func _build_result(result: String, actor: Node) -> Dictionary:
	return {
		"build": result,
		"target": name,
		"actor": actor.name if actor else "",
		"delivered_resources": delivered_resources,
		"required_resources": max(1, required_resources),
		"is_complete": is_complete,
	}


func _make_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0).darkened(0.45)
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
