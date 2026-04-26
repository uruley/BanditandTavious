extends Node3D

const PLAYER_SCENE := preload("res://level/scenes/lyra_player_clean.tscn")
const RIFLE_PICKUP_SCENE := preload("res://level/scenes/weapons/RiflePickup.tscn")
const RIFLE_RESOURCE := preload("res://level/data/weapons/rifle.tres")

var _player: Node3D
var _pickup: WeaponPickup

func _ready() -> void:
	_player = PLAYER_SCENE.instantiate() as Node3D
	_player.name = "1"
	_player.position = Vector3(-3.0, 0.0, 0.0)
	add_child(_player)
	_player.set_physics_process(false)

	_pickup = RIFLE_PICKUP_SCENE.instantiate() as WeaponPickup
	_pickup.name = "RifleBridgePickup"
	_pickup.position = Vector3(3.7, 0.9, 0.0)
	_pickup.auto_pickup = false
	add_child(_pickup)

	call_deferred("_run_bridge_test")

func _run_bridge_test() -> void:
	for _i in 8:
		await get_tree().physics_frame

	_player.global_position = Vector3.ZERO
	for _i in 10:
		await get_tree().physics_frame

	var inventory := _player.find_child("WeaponInventory", true, false) as WeaponInventoryComponent
	if inventory == null:
		push_error("WEAPON_PICKUP_LYRA_BRIDGE_TEST FAIL: missing WeaponInventory")
		return
	if inventory.current_weapon == RIFLE_RESOURCE:
		push_error("WEAPON_PICKUP_LYRA_BRIDGE_TEST FAIL: rifle auto-picked up despite auto_pickup=false")
		return

	_player.call("_check_interaction")
	for _i in 12:
		await get_tree().physics_frame
		if inventory.current_weapon == RIFLE_RESOURCE:
			break

	if inventory.current_weapon != RIFLE_RESOURCE:
		push_error("WEAPON_PICKUP_LYRA_BRIDGE_TEST FAIL: E interaction did not equip rifle")
		return

	_player.call("drop_weapon")
	for _i in 12:
		await get_tree().physics_frame
		if inventory.current_weapon == null and _find_live_rifle_pickup() != null:
			print("WEAPON_PICKUP_LYRA_BRIDGE_TEST PASS")
			return

	push_error("WEAPON_PICKUP_LYRA_BRIDGE_TEST FAIL: drop did not clear rifle and spawn pickup")

func _find_live_rifle_pickup() -> WeaponPickup:
	for node in get_tree().get_nodes_in_group("weapon_pickups"):
		if not is_instance_valid(node):
			continue
		var pickup := node as WeaponPickup
		if pickup == null or pickup.is_queued_for_deletion():
			continue
		if pickup.weapon_resource == RIFLE_RESOURCE and pickup.auto_pickup == false:
			return pickup
	return null
