@tool
extends Node3D

@export var weapon_resource: WeaponResource:
	set(value):
		weapon_resource = value
		_apply_preview()
@export var animation_name := "Pistol_Aim_Neutral":
	set(value):
		animation_name = value
		_apply_preview()
@export_range(0.0, 1.0, 0.01) var animation_pose := 0.45:
	set(value):
		animation_pose = value
		_apply_preview()
@export var character_path: NodePath = NodePath("Character")
@export var weapon_master_path: NodePath = NodePath("Character/Armature/Skeleton3D/RightHand/WeaponMaster")

func _ready() -> void:
	_apply_preview()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_apply_preview(false)

func _apply_preview(update_weapon: bool = true) -> void:
	if not is_inside_tree():
		return
	var weapon_master := get_node_or_null(weapon_master_path)
	if weapon_master:
		weapon_master.visible = weapon_resource != null
		if update_weapon and weapon_resource and weapon_master.get("weapon_resource") != weapon_resource:
			weapon_master.set("weapon_resource", weapon_resource)
		elif weapon_master.has_method("_apply_weapon_alignment"):
			weapon_master.call("_apply_weapon_alignment")

	var character := get_node_or_null(character_path)
	if character == null:
		return
	var animation_player := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null or animation_name == "" or not animation_player.has_animation(animation_name):
		return
	var animation := animation_player.get_animation(animation_name)
	if animation == null:
		return
	animation_player.play(animation_name)
	animation_player.seek(animation.length * animation_pose, true)
	if Engine.is_editor_hint():
		animation_player.pause()
