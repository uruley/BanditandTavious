@tool
extends Node3D

const FLOOR_SIZE := Vector3(20.0, 1.0, 20.0)
const ACTOR_HEIGHT := 1.8
const ACTOR_RADIUS := 0.45

const ACTORS := [
	{
		"name": "EnemyNPC",
		"position": Vector3(-3.0, 0.9, 0.0),
		"color": Color(0.82, 0.22, 0.22, 1.0),
	},
	{
		"name": "FriendlyNPC",
		"position": Vector3(0.0, 0.9, 0.0),
		"color": Color(0.24, 0.55, 0.9, 1.0),
	},
	{
		"name": "VillagerNPC",
		"position": Vector3(3.0, 0.9, 0.0),
		"color": Color(0.92, 0.76, 0.26, 1.0),
	},
]


func _ready() -> void:
	_ensure_scene_layout()


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_ensure_scene_layout")


func _ensure_scene_layout() -> void:
	_ensure_floor()
	for actor_data in ACTORS:
		_ensure_actor(actor_data)


func _ensure_floor() -> void:
	var floor := get_node_or_null("Floor") as MeshInstance3D
	if floor == null:
		floor = MeshInstance3D.new()
		floor.name = "Floor"
		add_child(floor)
		if Engine.is_editor_hint():
			floor.owner = get_tree().edited_scene_root

	var mesh := floor.mesh as BoxMesh
	if mesh == null:
		mesh = BoxMesh.new()
		floor.mesh = mesh
	mesh.size = FLOOR_SIZE
	floor.position = Vector3(0.0, -0.5, 0.0)
	floor.material_override = _make_material(Color(0.18, 0.2, 0.22, 1.0), 0.05, 0.95)


func _ensure_actor(actor_data: Dictionary) -> void:
	var actor_name := String(actor_data["name"])
	var actor := get_node_or_null(actor_name) as MeshInstance3D
	if actor == null:
		actor = MeshInstance3D.new()
		actor.name = actor_name
		add_child(actor)
		if Engine.is_editor_hint():
			actor.owner = get_tree().edited_scene_root

	var mesh := actor.mesh as CapsuleMesh
	if mesh == null:
		mesh = CapsuleMesh.new()
		actor.mesh = mesh
	mesh.mid_height = ACTOR_HEIGHT - (ACTOR_RADIUS * 2.0)
	mesh.radius = ACTOR_RADIUS
	actor.position = actor_data["position"]
	actor.material_override = _make_material(actor_data["color"], 0.0, 0.78)


func _make_material(albedo: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	return material
