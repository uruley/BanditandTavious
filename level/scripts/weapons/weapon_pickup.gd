class_name WeaponPickup
extends Area3D

@export var weapon_resource: WeaponResource:
	set(value):
		weapon_resource = value
		if is_node_ready():
			_refresh_visuals()
@export var visual_root_path: NodePath = NodePath("VisualRoot")
@export var pickup_enabled := true
@export var auto_pickup := true
@export var consume_on_pickup := true

var _consumed := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	monitorable = true
	add_to_group("weapon_pickups")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_refresh_visuals()

func interact(player: Node3D) -> bool:
	return _try_pick_up_from(player)

func _on_body_entered(body: Node3D) -> void:
	if not auto_pickup:
		return
	_try_pick_up_from(body)

func configure_for_drop() -> void:
	pickup_enabled = true
	auto_pickup = false
	consume_on_pickup = true
	_consumed = false

func _try_pick_up_from(node: Node) -> bool:
	if _consumed or not pickup_enabled or weapon_resource == null:
		return false
	var inventory := _find_inventory(node)
	if inventory == null:
		return false
	if not inventory.try_pick_up(weapon_resource, self):
		return false

	print("WEAPON_PICKUP: equipped ", weapon_resource.weapon_name)
	if consume_on_pickup:
		_consumed = true
		queue_free()
	return true

func _find_inventory(node: Node) -> WeaponInventoryComponent:
	var current := node
	while current:
		if current is WeaponInventoryComponent:
			return current as WeaponInventoryComponent
		var child := current.find_child("WeaponInventory", true, false)
		if child is WeaponInventoryComponent:
			return child as WeaponInventoryComponent
		current = current.get_parent()
	return null

func _refresh_visuals() -> void:
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root == null:
		return
	for child in visual_root.get_children():
		child.queue_free()
	if weapon_resource == null or weapon_resource.weapon_visuals == null:
		return
	var visuals := weapon_resource.weapon_visuals.instantiate() as Node3D
	if visuals == null:
		return
	visual_root.add_child(visuals)
