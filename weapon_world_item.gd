@tool
extends RigidBody3D

@export var weapon_id: String = "pistol"
@export var weapon_resource: WeaponResource: # New modular data
	set(val):
		weapon_resource = val
		update_visuals()
@export var weapon_visual_scene: PackedScene:
	set(val):
		weapon_visual_scene = val
		update_visuals()
@export var world_item_scene: PackedScene # Scene of THIS item for re-dropping
@export var auto_pickup := true
@export var pickup_delay := 0.25

var _can_pick_up := false
var _pickup_consumed := false

func _ready() -> void:
	if not Engine.is_editor_hint():
		if world_item_scene == null:
			# Auto-assign this scene if not set
			world_item_scene = load(scene_file_path)
		_wire_interaction_area()
		_start_pickup_delay()
	update_visuals()

func update_visuals() -> void:
	var model_root = get_node_or_null("Visuals/PistolModel")
	if not model_root:
		model_root = get_node_or_null("Visuals")
	
	if not model_root:
		return
		
	# Clear existing visuals
	for child in model_root.get_children():
		child.free() # Use free() in @tool mode for immediate cleanup
	
	# 1. Try new Resource visuals
	if weapon_resource and weapon_resource.weapon_visuals:
		var model = weapon_resource.weapon_visuals.instantiate()
		model_root.add_child(model)
		return

	# 2. Try legacy scene visuals
	if weapon_visual_scene:
		var model = weapon_visual_scene.instantiate()
		model_root.add_child(model)
		return
		
	# 3. Last resort fallback
	if not Engine.is_editor_hint():
		var fallback = load("res://BlackPistol.tscn")
		if fallback:
			var model = fallback.instantiate()
			model_root.add_child(model)

func interact(player: Node3D) -> void:
	if _pickup_consumed or is_queued_for_deletion():
		return
	if player and player.has_method("pick_up_weapon"):
		_pickup_consumed = true
		player.pick_up_weapon(self)
		if not is_queued_for_deletion():
			_pickup_consumed = false

func _wire_interaction_area() -> void:
	var area := get_node_or_null("InteractionArea") as Area3D
	if area == null:
		return
	area.monitoring = true
	area.monitorable = true
	if not area.body_entered.is_connected(_on_interaction_body_entered):
		area.body_entered.connect(_on_interaction_body_entered)
	if not area.area_entered.is_connected(_on_interaction_area_entered):
		area.area_entered.connect(_on_interaction_area_entered)

func _start_pickup_delay() -> void:
	_can_pick_up = pickup_delay <= 0.0
	if _can_pick_up:
		return
	await get_tree().create_timer(pickup_delay).timeout
	_can_pick_up = true

func _on_interaction_body_entered(body: Node3D) -> void:
	_try_auto_pickup(body)

func _on_interaction_area_entered(area: Area3D) -> void:
	_try_auto_pickup(area)

func _try_auto_pickup(node: Node) -> void:
	if not auto_pickup or not _can_pick_up:
		return
	var player := _find_pickup_owner(node)
	if player:
		interact(player)

func _find_pickup_owner(node: Node) -> Node3D:
	var current := node
	while current:
		if current != self and current is Node3D and current.has_method("pick_up_weapon"):
			return current as Node3D
		current = current.get_parent()
	return null
