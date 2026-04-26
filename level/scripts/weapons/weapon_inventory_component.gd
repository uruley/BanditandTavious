class_name WeaponInventoryComponent
extends Node

signal weapon_equipped(weapon_resource: WeaponResource)
signal weapon_dropped(weapon_resource: WeaponResource)

const DEFAULT_PICKUP_SCENE_PATH := "res://level/scenes/weapons/WeaponPickup.tscn"

@export var weapon_master_path: NodePath
@export var drop_pickup_scene: PackedScene
@export var dropped_pickups_auto_pickup := false
@export var current_weapon: WeaponResource

var _weapon_master: Node3D = null

func _ready() -> void:
	_resolve_weapon_master()
	if current_weapon:
		equip_weapon(current_weapon)

func try_pick_up(weapon_resource: WeaponResource, _source: Node = null) -> bool:
	if weapon_resource == null:
		return false
	return equip_weapon(weapon_resource)

func equip_weapon(weapon_resource: WeaponResource) -> bool:
	if weapon_resource == null:
		return false
	_resolve_weapon_master()
	if _weapon_master == null:
		push_warning("WeaponInventoryComponent could not find a WeaponMaster.")
		return false

	current_weapon = weapon_resource
	_weapon_master.visible = true
	_weapon_master.set("weapon_resource", weapon_resource)
	weapon_equipped.emit(weapon_resource)
	return true

func clear_weapon() -> void:
	if current_weapon == null:
		return
	var dropped_resource := current_weapon
	current_weapon = null
	_resolve_weapon_master()
	if _weapon_master:
		_weapon_master.visible = false
		_weapon_master.set("weapon_resource", null)
	weapon_dropped.emit(dropped_resource)

func drop_current_weapon(drop_transform: Transform3D) -> Node3D:
	if current_weapon == null:
		return null
	var pickup_scene := drop_pickup_scene
	if pickup_scene == null:
		pickup_scene = load(DEFAULT_PICKUP_SCENE_PATH)
	if pickup_scene == null:
		push_warning("WeaponInventoryComponent could not load WeaponPickup scene.")
		return null

	var dropped_resource := current_weapon
	var pickup := pickup_scene.instantiate() as Node3D
	if pickup == null:
		return null
	if pickup.has_method("configure_for_drop"):
		pickup.configure_for_drop()
	pickup.set("weapon_resource", dropped_resource)
	get_tree().current_scene.add_child(pickup)
	pickup.global_transform = drop_transform
	pickup.set("auto_pickup", dropped_pickups_auto_pickup)
	clear_weapon()
	return pickup

func has_weapon() -> bool:
	return current_weapon != null

func get_weapon_master() -> Node3D:
	_resolve_weapon_master()
	return _weapon_master

func _resolve_weapon_master() -> void:
	if _weapon_master and is_instance_valid(_weapon_master):
		return
	if weapon_master_path != NodePath(""):
		_weapon_master = get_node_or_null(weapon_master_path) as Node3D
		if _weapon_master:
			return

	var owner_node := get_parent()
	if owner_node == null:
		return
	_weapon_master = owner_node.find_child("WeaponMaster", true, false) as Node3D
