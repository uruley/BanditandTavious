extends Area3D

@export_enum("food", "water", "resource") var target_type: String = "food"
@export var capacity: int = 1
@export var label_text: String = ""
@export var marker_color: Color = Color(0.4, 1.0, 0.4, 1.0)
@export var marker_size: Vector3 = Vector3(1.4, 0.08, 1.4)

var reserved_by: Array[String] = []


func _ready() -> void:
	add_to_group("lyra_ai_target")
	add_to_group("lyra_ai_target_%s" % target_type)
	_configure_marker()


func can_reserve(actor_id: String) -> bool:
	return reserved_by.has(actor_id) or reserved_by.size() < max(1, capacity)


func reserve(actor_id: String) -> bool:
	if not can_reserve(actor_id):
		return false
	if not reserved_by.has(actor_id):
		reserved_by.append(actor_id)
	return true


func release(actor_id: String) -> void:
	reserved_by.erase(actor_id)


func get_display_name() -> String:
	return label_text if label_text != "" else "%s:%s" % [target_type, name]


func _configure_marker() -> void:
	if get_node_or_null("MarkerMesh") == null:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "MarkerMesh"
		var mesh := BoxMesh.new()
		mesh.size = marker_size
		mesh_instance.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = marker_color
		material.emission_enabled = true
		material.emission = marker_color.darkened(0.35)
		mesh_instance.material_override = material
		add_child(mesh_instance)

	if get_node_or_null("CollisionShape3D") == null:
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(max(marker_size.x, 0.75), 0.6, max(marker_size.z, 0.75))
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("Label3D") == null:
		var label := Label3D.new()
		label.name = "Label3D"
		label.text = get_display_name()
		label.position = Vector3(0.0, 0.65, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		add_child(label)
