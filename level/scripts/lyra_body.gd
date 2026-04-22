extends Node3D

const LERP_VELOCITY := 0.15

@export_category("Objects")
@export var _character: CharacterBody3D = null

var _animation_player: AnimationPlayer = null
var _model_root: Node3D = null
var _model_rest_rotation_y := 0.0

func _ready() -> void:
	_animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_model_root = get_node_or_null("Armature") as Node3D
	if _model_root == null:
		_model_root = self
	_model_rest_rotation_y = _model_root.rotation.y

func apply_rotation(target_velocity: Vector3) -> void:
	if _model_root == null:
		return
	var planar_velocity := Vector3(target_velocity.x, 0.0, target_velocity.z)
	if planar_velocity.length_squared() == 0.0:
		return
	var target_yaw := atan2(-planar_velocity.x, -planar_velocity.z) + _model_rest_rotation_y
	var new_rotation_y := lerp_angle(_model_root.rotation.y, target_yaw, LERP_VELOCITY)
	_model_root.rotation.y = new_rotation_y
	sync_player_rotation.rpc(new_rotation_y)

func animate(target_velocity: Vector3) -> void:
	if _animation_player == null or _character == null:
		return

	var target_animation := _pick_animation(target_velocity)
	if target_animation == "":
		return

	if _animation_player.current_animation == target_animation and _animation_player.is_playing():
		return
	_animation_player.play(target_animation)

func _pick_animation(target_velocity: Vector3) -> String:
	if _animation_player == null or _character == null:
		return ""

	if not _character.is_on_floor():
		return _first_available(["Jump", "Jump_Start", "Jump_Land", "Idle"])

	var planar_speed := Vector2(target_velocity.x, target_velocity.z).length()
	if planar_speed <= 0.05:
		return _first_available(["Idle", "Pistol_Idle"])

	if _character.has_method("is_running") and _character.is_running():
		return _first_available(["Sprint", "Jog_Fwd", "Walk"])

	return _first_available(["Walk", "Jog_Fwd", "Sprint", "Idle"])

func _first_available(candidates: Array[String]) -> String:
	for animation_name in candidates:
		if _animation_player.has_animation(animation_name):
			return animation_name
	return ""

@rpc("any_peer", "reliable")
func sync_player_rotation(rotation_y: float) -> void:
	if _model_root == null:
		_model_root = get_node_or_null("Armature") as Node3D
		if _model_root == null:
			_model_root = self
	_model_root.rotation.y = rotation_y
