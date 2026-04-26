extends Node3D

@export var label_text: String = ""
@export var marker_color: Color = Color(0.45, 0.85, 1.0, 1.0)
@export var marker_size: Vector3 = Vector3(0.9, 0.08, 0.9)


func _ready() -> void:
	add_to_group("lyra_ai_waypoint")
	_configure_marker()


func get_display_name() -> String:
	return label_text if label_text != "" else name


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
		material.emission = marker_color.darkened(0.45)
		mesh_instance.material_override = material
		add_child(mesh_instance)

	if get_node_or_null("Label3D") == null:
		var label := Label3D.new()
		label.name = "Label3D"
		label.text = get_display_name()
		label.position = Vector3(0.0, 0.7, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		add_child(label)
