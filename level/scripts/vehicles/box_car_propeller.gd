extends CharacterBody3D

@export var max_speed := 10.0
@export var acceleration := 16.0
@export var braking := 18.0
@export var coasting_drag := 8.0
@export var turn_speed := 1.8
@export var steer_angle_degrees := 28.0
@export var wheel_radius := 0.35
@export var propeller_spin_scale := 8.0
@export var gravity := 24.0
@export var auto_drive := false
@export var auto_drive_speed := 3.0
@export var preview_visual_animation := true
@export var preview_visual_speed := 3.0

@onready var model: Node3D = $Visual/BoxCarModel
@onready var wheel_nodes: Array[Node3D] = [
	$Visual/BoxCarModel/Wheel_FL,
	$Visual/BoxCarModel/Wheel_FR,
	$Visual/BoxCarModel/Wheel_RL,
	$Visual/BoxCarModel/Wheel_RR,
]
@onready var propeller_root: Node3D = $Visual/BoxCarModel/Hub # I'll use Hub or a container

var forward_speed := 0.0
var wheel_spin_total := 0.0
var propeller_spin_total := 0.0

func _ready() -> void:
	# _apply_visual_materials() # Disabled as we use Blender materials
	_add_wheel_spin_markers()

func _physics_process(delta: float) -> void:
	var throttle := _get_throttle_input()
	var steer := _get_steer_input()

	if auto_drive and is_zero_approx(throttle):
		throttle = 1.0

	var target_speed := throttle * max_speed
	if auto_drive and throttle > 0.0:
		target_speed = min(target_speed, auto_drive_speed)

	if not is_zero_approx(throttle):
		var rate := acceleration if absf(target_speed) > absf(forward_speed) else braking
		forward_speed = move_toward(forward_speed, target_speed, rate * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, coasting_drag * delta)

	var speed_ratio: float = clampf(absf(forward_speed) / max_speed, 0.0, 1.0)
	if speed_ratio > 0.01:
		rotate_y(steer * turn_speed * speed_ratio * signf(forward_speed) * delta)

	var vertical_velocity := velocity.y
	if is_on_floor() and vertical_velocity < 0.0:
		vertical_velocity = 0.0
	else:
		vertical_velocity -= gravity * delta

	velocity = -global_transform.basis.z * forward_speed
	velocity.y = vertical_velocity
	move_and_slide()

	_update_vehicle_visuals(steer, delta)

func _get_throttle_input() -> float:
	var input := 0.0
	if Input.is_physical_key_pressed(KEY_W):
		input += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input -= 1.0
	return clampf(input, -1.0, 1.0)

func _get_steer_input() -> float:
	var input := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		input += 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input -= 1.0
	return clampf(input, -1.0, 1.0)

func _update_vehicle_visuals(steer: float, delta: float) -> void:
	var steer_angle := deg_to_rad(steer_angle_degrees) * steer
	# Front wheels in Blender model: Wheel_FL, Wheel_FR
	$Visual/BoxCarModel/Wheel_FL.rotation.y = steer_angle
	$Visual/BoxCarModel/Wheel_FR.rotation.y = steer_angle

	var visual_speed := forward_speed
	if preview_visual_animation and absf(visual_speed) < 0.05:
		visual_speed = preview_visual_speed

	var wheel_delta := (visual_speed / maxf(wheel_radius, 0.01)) * delta
	for wheel in wheel_nodes:
		wheel.rotate_object_local(Vector3.UP, wheel_delta)
	wheel_spin_total += absf(wheel_delta)

	var propeller_delta := absf(visual_speed) * propeller_spin_scale * delta
	# Propeller Hub in Blender model
	propeller_root.rotate_object_local(Vector3.FORWARD, propeller_delta)
	propeller_spin_total += propeller_delta

func get_forward_speed() -> float:
	return forward_speed

func get_visual_spin_totals() -> Dictionary:
	return {
		"wheel": wheel_spin_total,
		"propeller": propeller_spin_total,
	}

func _add_wheel_spin_markers() -> void:
	var marker_material := _make_material(Color(1.0, 0.8, 0.05))
	for wheel in wheel_nodes:
		if wheel.has_node("SpinMarker"):
			continue

		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(0.12, 0.36, 0.66)

		var marker := MeshInstance3D.new()
		marker.name = "SpinMarker"
		marker.mesh = marker_mesh
		marker.material_override = marker_material
		wheel.add_child(marker)

func _apply_visual_materials() -> void:
	var body_material := _make_material(Color(0.12, 0.38, 0.95))
	var cabin_material := _make_material(Color(0.08, 0.12, 0.18))
	var wheel_material := _make_material(Color(0.02, 0.02, 0.025))
	var propeller_material := _make_material(Color(1.0, 0.18, 0.08))

	_set_csg_material("Visual/Body", body_material)
	_set_csg_material("Visual/Cabin", cabin_material)
	_set_csg_material("Visual/Nose", body_material)
	_set_csg_material("Visual/PropellerRoot/Hub", cabin_material)
	_set_csg_material("Visual/PropellerRoot/BladeHorizontal", propeller_material)
	_set_csg_material("Visual/PropellerRoot/BladeVertical", propeller_material)

	for wheel in wheel_nodes:
		wheel.set("material", wheel_material)

func _set_csg_material(node_path: NodePath, material: StandardMaterial3D) -> void:
	var node := get_node_or_null(node_path)
	if node != null:
		node.set("material", material)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	return material
