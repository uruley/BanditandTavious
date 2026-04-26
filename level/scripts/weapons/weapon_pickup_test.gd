extends Node3D

const PICKUP_SCENE := preload("res://level/scenes/weapons/WeaponPickup.tscn")
const WEAPON_MASTER_SCENE := preload("res://level/scenes/weapons/WeaponMaster.tscn")
const PISTOL_RESOURCE := preload("res://level/data/weapons/pistol.tres")

var _player: CharacterBody3D
var _inventory: WeaponInventoryComponent
var _pickup: WeaponPickup

func _ready() -> void:
	_create_player()
	_create_pickup()
	call_deferred("_run_pickup_test")

func _create_player() -> void:
	_player = CharacterBody3D.new()
	_player.name = "PickupTestPlayer"
	_player.collision_layer = 1
	_player.collision_mask = 6
	_player.position = Vector3(-3.0, 0.0, 0.0)
	add_child(_player)

	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	_player.add_child(shape)

	var weapon_master := WEAPON_MASTER_SCENE.instantiate() as Node3D
	weapon_master.name = "WeaponMaster"
	weapon_master.visible = false
	_player.add_child(weapon_master)

	_inventory = WeaponInventoryComponent.new()
	_inventory.name = "WeaponInventory"
	_inventory.weapon_master_path = NodePath("../WeaponMaster")
	_player.add_child(_inventory)

func _create_pickup() -> void:
	_pickup = PICKUP_SCENE.instantiate() as WeaponPickup
	_pickup.name = "PistolPickup"
	_pickup.weapon_resource = PISTOL_RESOURCE
	_pickup.position = Vector3(0.0, 0.9, 0.0)
	add_child(_pickup)

func _run_pickup_test() -> void:
	await get_tree().physics_frame
	_player.global_position = Vector3(0.0, 0.0, 0.0)
	for _i in 6:
		await get_tree().physics_frame

	if _inventory.current_weapon == PISTOL_RESOURCE and (_pickup == null or not is_instance_valid(_pickup) or _pickup.is_queued_for_deletion()):
		print("WEAPON_PICKUP_TEST PASS")
	else:
		push_error("WEAPON_PICKUP_TEST FAIL: pickup did not equip pistol resource")
