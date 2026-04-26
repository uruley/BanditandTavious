class_name BachtaviousPlayer
extends CharacterBody3D

const SPEED := 5.0
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSIBILITY := 0.005
const MIN_PITCH := -PI / 4.0
const MAX_PITCH := PI / 6.0
const TRIGGER_THRESHOLD := 0.5
const AIM_TRIGGER_THRESHOLD := 0.5
const CROUCH_SPEED := 2.5
const PROJECTILE_SPEED := 45.0
const PROJECTILE_RANGE := 200.0
const RECOIL_POSITION_KICK := Vector3(0.0, 0.015, 0.08)
const RECOIL_ROTATION_KICK := Vector3(-0.16, 0.05, 0.08)
const RECOIL_RETURN_SPEED := 14.0
const AIM_BODY_TURN_LERP := 0.25
const DEFAULT_FOV := 75.0
const ADS_FOV := 50.0
const DEFAULT_SPRING_LENGTH := 2.5
const ADS_SPRING_LENGTH := 1.5
const DEFAULT_H_OFFSET := 0.0
const ADS_H_OFFSET := 0.15
const VAULT_MIN_HEIGHT_RATIO := 0.4
const VAULT_MAX_HEIGHT_RATIO := 0.8
const MANTLE_MAX_HEIGHT_RATIO := 1.4
const LEDGE_MIN_NORMAL_Y := 0.6
const DEBUG_SCREENSHOT_KEY := KEY_F12
const PICKUP_QUERY_MASK := 7
const PICKUP_INTERACTION_RADIUS := 4.0

# MANUAL WEAPON COORDINATES (Edit these until it looks right!)
const RIFLE_POS := Vector3(0.008, 0.158, -0.105)
const RIFLE_ROT := Vector3(0.072, -1.745, -1.395)
const RIFLE_SCALE := Vector3(0.91, 0.91, 0.91)

@onready var nickname: Label3D = $PlayerNick/Nickname
@onready var chat_label: Label3D = $PlayerChat/Text

@export_category("Objects")
@export var body_root: Node3D = null
@export var spring_arm_offset: Node3D = null
@export var spring_arm: SpringArm3D = null
@export var camera_node: Camera3D = null
@export var animation_tree: AnimationTree = null
@export var weapon_master: Node3D = null # WeaponMaster container
@export var weapon_inventory: WeaponInventoryComponent = null
@export var current_weapon: WeaponResource = null
@export var forward_ray: RayCast3D = null
@export var head_ray: RayCast3D = null
@export var ledge_ray: RayCast3D = null

var _respawn_point := Vector3(0, 5, 0)
var _camera_pitch := 0.0
var _camera_tween: Tween
var _parkour_tween: Tween
var _projectile_scene := preload("res://simple_projectile.tscn")
var _weapon_world_item_scene := preload("res://WeaponWorldItem.tscn")
var _current_weapon_world_scene : PackedScene = null
var _one_shot_animation := ""
var _shoot_was_pressed := false
var _punch_was_pressed := false
var _drop_was_pressed := false
var _interact_was_pressed := false
var _has_weapon := true
var _is_aiming := false
var _is_parkouring := false
var _state_animation_lock := ""
var _was_on_floor := true
var _weapon_rest_position := Vector3.ZERO
var _weapon_rest_rotation := Vector3.ZERO
var _recoil_position_offset := Vector3.ZERO
var _recoil_rotation_offset := Vector3.ZERO
var _body_rest_rotation_y := 0.0
var _animation_player: AnimationPlayer = null
var _vault_root_motion_active := false
var _vault_root_motion_time_left := 0.0
var _debug_screenshot_was_pressed := false

func _enter_tree() -> void:
	var local_camera := get_node_or_null("SpringArmOffset/SpringArm3D/Camera3D") as Camera3D
	if local_camera:
		local_camera.current = false

func _ready() -> void:
	_resolve_nodes()
	_disable_preview_nodes()
	_consolidate_libraries()

	if camera_node:
		_camera_pitch = spring_arm.rotation.x if spring_arm else camera_node.rotation.x
		camera_node.current = false
		camera_node.fov = DEFAULT_FOV
		camera_node.h_offset = DEFAULT_H_OFFSET
	if spring_arm:
		spring_arm.spring_length = DEFAULT_SPRING_LENGTH
	if weapon_master:
		_weapon_rest_position = weapon_master.position
		_weapon_rest_rotation = weapon_master.rotation
		_has_weapon = weapon_master.visible
		if current_weapon:
			weapon_master.set("weapon_resource", current_weapon)
		elif weapon_master.get("weapon_resource") is WeaponResource:
			current_weapon = weapon_master.get("weapon_resource") as WeaponResource
		if weapon_master.has_signal("fired") and not weapon_master.fired.is_connected(_on_weapon_fired):
			weapon_master.fired.connect(_on_weapon_fired)
	_configure_weapon_inventory()
	if body_root:
		_body_rest_rotation_y = body_root.rotation.y
	chat_label.hide()

	if not await _configure_multiplayer_state():
		push_warning("Player spawned without a replicated peer id: %s" % name)
		return

func _resolve_nodes() -> void:
	if body_root == null:
		body_root = get_node_or_null("Lyra")
	if body_root == null:
		body_root = get_node_or_null("Bachtavious")
	if body_root == null:
		for child in get_children():
			if child is Node3D and child.has_node("AnimationPlayer"):
				body_root = child
				break
	if spring_arm_offset == null:
		spring_arm_offset = get_node_or_null("SpringArmOffset")
	if spring_arm == null:
		spring_arm = get_node_or_null("SpringArmOffset/SpringArm3D")
	if camera_node == null:
		camera_node = get_node_or_null("SpringArmOffset/SpringArm3D/Camera3D")
	if animation_tree == null and body_root:
		animation_tree = body_root.get_node_or_null("AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = get_node_or_null("Lyra/AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = get_node_or_null("Bachtavious/AnimationTree") as AnimationTree
	
	if weapon_master == null and body_root:
		weapon_master = body_root.get_node_or_null("Armature/Skeleton3D/RightHand/WeaponMaster")
	if weapon_master == null:
		weapon_master = get_node_or_null("Bachtavious/Armature/Skeleton3D/RightHand/WeaponMaster")
	if weapon_inventory == null:
		weapon_inventory = get_node_or_null("WeaponInventory") as WeaponInventoryComponent
	if weapon_inventory == null:
		weapon_inventory = find_child("WeaponInventory", true, false) as WeaponInventoryComponent
	if weapon_inventory == null:
		weapon_inventory = WeaponInventoryComponent.new()
		weapon_inventory.name = "WeaponInventory"
		add_child(weapon_inventory)

	if forward_ray == null:
		forward_ray = get_node_or_null("Scanner/ForwardRay")
	if head_ray == null:
		head_ray = get_node_or_null("Scanner/HeadRay")
	if ledge_ray == null:
		ledge_ray = get_node_or_null("Scanner/LedgeRay")
	if _animation_player == null:
		if body_root:
			_animation_player = body_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		_animation_player = get_node_or_null("Lyra/AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		_animation_player = get_node_or_null("Bachtavious/AnimationPlayer") as AnimationPlayer

func _configure_weapon_inventory() -> void:
	if weapon_inventory == null:
		return
	if weapon_master:
		weapon_inventory.weapon_master_path = weapon_inventory.get_path_to(weapon_master)
	if current_weapon:
		weapon_inventory.current_weapon = current_weapon
	elif weapon_inventory.current_weapon:
		current_weapon = weapon_inventory.current_weapon
	if not weapon_inventory.weapon_equipped.is_connected(_on_inventory_weapon_equipped):
		weapon_inventory.weapon_equipped.connect(_on_inventory_weapon_equipped)
	if not weapon_inventory.weapon_dropped.is_connected(_on_inventory_weapon_dropped):
		weapon_inventory.weapon_dropped.connect(_on_inventory_weapon_dropped)

func _disable_preview_nodes() -> void:
	if Engine.is_editor_hint():
		return
	if body_root == null:
		return
	for child_name in ["WorldEnvironment", "DirectionalLight3D", "Camera3D"]:
		var node := body_root.get_node_or_null(child_name)
		if node:
			node.queue_free()

func _configure_multiplayer_state() -> bool:
	for _attempt in 4:
		await get_tree().process_frame
		var peer_id := str(name).to_int()
		var local_peer_id := multiplayer.get_unique_id()
		if peer_id <= 0 or local_peer_id <= 0:
			continue
		set_multiplayer_authority(peer_id)
		var is_local_player := peer_id == local_peer_id
		if camera_node:
			camera_node.current = is_local_player
			if is_local_player:
				camera_node.make_current()
		if is_local_player:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return true
	if camera_node:
		camera_node.current = false
	return false

func _consolidate_libraries() -> void:
	if _animation_player == null:
		if body_root:
			_animation_player = body_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		_animation_player = get_node_or_null("Lyra/AnimationPlayer") as AnimationPlayer
	if _animation_player == null:
		_animation_player = get_node_or_null("Bachtavious/AnimationPlayer") as AnimationPlayer
		if _animation_player == null:
			return
	if body_root == null:
		body_root = get_node_or_null("Lyra")
	if body_root == null:
		body_root = get_node_or_null("Bachtavious")
	if body_root:
		_animation_player.root_node = _animation_player.get_path_to(body_root)

	if not _animation_player.has_animation_library("parkour") and not _animation_player.has_animation_library("parkour_pro"):
		var parkour_lib_path := "res://assets/animations/parkour_pro.res"
		if FileAccess.file_exists(parkour_lib_path):
			var parkour_lib = load(parkour_lib_path)
			if parkour_lib:
				_animation_player.add_animation_library("parkour", parkour_lib)

	if not _animation_player.has_animation_library("locomotion"):
		var locomotion_lib_path := "res://assets/animations/locomotion_base.res"
		if FileAccess.file_exists(locomotion_lib_path):
			var locomotion_lib = load(locomotion_lib_path)
			if locomotion_lib:
				_animation_player.add_animation_library("locomotion", locomotion_lib)

	if not _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_finished)

	if not _animation_player.is_playing() and _animation_player.has_animation("Idle"):
		_animation_player.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == DEBUG_SCREENSHOT_KEY:
		_capture_debug_screenshot()
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSIBILITY)
		if spring_arm:
			_camera_pitch = clamp(_camera_pitch - event.relative.y * MOUSE_SENSIBILITY, MIN_PITCH, MAX_PITCH)
			spring_arm.rotation.x = _camera_pitch

func _process(delta: float) -> void:
	if weapon_master == null:
		return
	_recoil_position_offset = _recoil_position_offset.lerp(Vector3.ZERO, delta * RECOIL_RETURN_SPEED)
	_recoil_rotation_offset = _recoil_rotation_offset.lerp(Vector3.ZERO, delta * RECOIL_RETURN_SPEED)
	weapon_master.position = _weapon_rest_position + _recoil_position_offset
	weapon_master.rotation = _weapon_rest_rotation + _recoil_rotation_offset
	if body_root and _is_aiming and spring_arm_offset:
		body_root.global_rotation.y = lerp_angle(body_root.global_rotation.y, spring_arm_offset.global_rotation.y, AIM_BODY_TURN_LERP)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var screenshot_pressed := Input.is_physical_key_pressed(DEBUG_SCREENSHOT_KEY)
	if screenshot_pressed and not _debug_screenshot_was_pressed:
		_capture_debug_screenshot()
	_debug_screenshot_was_pressed = screenshot_pressed

	var current_scene := get_tree().get_current_scene()
	if current_scene and current_scene.has_method("is_chat_visible") and current_scene.is_chat_visible() and is_on_floor():
		freeze()
		return

	if _is_drop_just_pressed() and _has_weapon:
		drop_weapon()
	
	if _is_interact_just_pressed():
		_check_interaction()

	var was_aiming := _is_aiming
	_is_aiming = _is_aim_pressed() if _has_weapon else false
	if was_aiming != _is_aiming:
		_toggle_ads(_is_aiming)

	if _has_weapon and weapon_master:
		var want_to_fire := false
		if current_weapon and current_weapon.is_automatic:
			want_to_fire = _is_shoot_pressed()
		else:
			want_to_fire = _is_shoot_just_pressed()

		if want_to_fire:
			if weapon_master.has_method("fire") and weapon_master.fire():
				_play_one_shot("Pistol_Shoot")
				_apply_weapon_recoil()
	elif _is_punch_just_pressed():
		_play_one_shot("Punch_Jab")

	_check_fall_and_respawn()

func freeze() -> void:
	velocity = Vector3.ZERO
	_update_animation(false, false)

func animate_body(_vel: Vector3) -> void:
	var is_crouching := Input.is_physical_key_pressed(KEY_CTRL)
	var is_sprinting := Input.is_physical_key_pressed(KEY_SHIFT) and not is_crouching
	var just_landed := not _was_on_floor and is_on_floor()
	_was_on_floor = is_on_floor()
	if just_landed:
		_play_one_shot("Jump_Land")
	_update_animation(is_crouching, is_sprinting)

func rotate_body(vel: Vector3) -> void:
	if body_root and vel.length_squared() > 0.1 and not _is_aiming:
		var target_angle = atan2(-vel.x, -vel.z)
		body_root.global_rotation.y = lerp_angle(body_root.global_rotation.y, target_angle, 0.15)

func get_move_direction() -> Vector3:
	var input_direction := _get_move_input()
	var direction := Vector3.ZERO
	if input_direction.length() > 0.0:
		var forward := -spring_arm_offset.global_transform.basis.z if spring_arm_offset else -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := spring_arm_offset.global_transform.basis.x if spring_arm_offset else global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		direction = (right * input_direction.x) + (forward * -input_direction.y)
		direction = direction.normalized()
	return direction

func _check_fall_and_respawn() -> void:
	if global_position.y < -15.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO

func _update_animation(is_crouching: bool, is_sprinting: bool) -> void:
	if _animation_player == null:
		return
	if _one_shot_animation != "":
		return
	if _state_animation_lock != "":
		if _animation_player.current_animation != _state_animation_lock and _animation_player.has_animation(_state_animation_lock):
			_animation_player.play(_state_animation_lock)
		return
	var next_animation := "Idle"
	if not is_on_floor():
		next_animation = "Jump"
	elif is_crouching:
		next_animation = "Crouch_Fwd" if Vector2(velocity.x, velocity.z).length() > 0.1 else "Crouch_Idle"
	elif _is_aiming:
		next_animation = "Pistol_Aim_Neutral"
	elif Vector2(velocity.x, velocity.z).length() > 0.1:
		next_animation = "Sprint" if is_sprinting else "Walk"
	if _animation_player.current_animation != next_animation and _animation_player.has_animation(next_animation):
		_animation_player.play(next_animation)

func _is_aim_pressed() -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return true
	for device in Input.get_connected_joypads():
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT) > AIM_TRIGGER_THRESHOLD:
			return true
	return false

func _is_shoot_just_pressed() -> bool:
	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for device in Input.get_connected_joypads():
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD:
			is_pressed = true
			break
	var just_pressed := is_pressed and not _shoot_was_pressed
	_shoot_was_pressed = is_pressed
	return just_pressed

func _is_shoot_pressed() -> bool:
	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	for device in Input.get_connected_joypads():
		if Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_THRESHOLD:
			is_pressed = true
			break
	return is_pressed

func _is_punch_just_pressed() -> bool:
	var is_pressed := Input.is_physical_key_pressed(KEY_F)
	var just_pressed := is_pressed and not _punch_was_pressed
	_punch_was_pressed = is_pressed
	return just_pressed

func _is_drop_just_pressed() -> bool:
	var is_pressed := Input.is_physical_key_pressed(KEY_G)
	var just_pressed := is_pressed and not _drop_was_pressed
	_drop_was_pressed = is_pressed
	return just_pressed

func _is_interact_just_pressed() -> bool:
	var is_pressed := Input.is_physical_key_pressed(KEY_E)
	var just_pressed := is_pressed and not _interact_was_pressed
	_interact_was_pressed = is_pressed
	return just_pressed

func drop_weapon() -> void:
	if not _has_weapon or weapon_master == null:
		return
		
	print("Dropping weapon...")
	if weapon_inventory and weapon_inventory.current_weapon:
		var drop_transform := weapon_master.global_transform
		drop_transform.origin += (-global_transform.basis.z * 1.0) + Vector3.UP * 0.2
		var dropped := weapon_inventory.drop_current_weapon(drop_transform)
		if dropped:
			current_weapon = null
			_has_weapon = false
			if _is_aiming:
				_toggle_ads(false)
				_is_aiming = false
			return

	var drop_scene = _current_weapon_world_scene if _current_weapon_world_scene else _weapon_world_item_scene
	var drop_item = drop_scene.instantiate()
	get_tree().current_scene.add_child(drop_item)
	if current_weapon:
		drop_item.set("weapon_resource", current_weapon)
	if drop_item.get("world_item_scene") == null:
		drop_item.set("world_item_scene", drop_scene)
	
	drop_item.global_position = weapon_master.global_position
	drop_item.global_rotation = weapon_master.global_rotation
	
	# Throw it forward a bit
	var throw_dir = -global_transform.basis.z + Vector3(0, 0.5, 0)
	drop_item.apply_central_impulse(throw_dir * 5.0)
	
	_has_weapon = false
	current_weapon = null
	weapon_master.visible = false

	if _is_aiming:
		_toggle_ads(false)
		_is_aiming = false

func pick_up_weapon(weapon_item: Node3D) -> void:
	if weapon_master == null:
		return
		
	var resource = weapon_item.get("weapon_resource") as WeaponResource
	
	# LEGACY FALLBACK: If the item has no resource, load the default pistol
	if not resource:
		print("Legacy weapon detected, loading default pistol.tres")
		resource = load("res://level/data/weapons/pistol.tres")
		
	if resource:
		print("Picking up weapon: ", resource.weapon_name)
		if weapon_inventory and weapon_inventory.try_pick_up(resource, weapon_item):
			_current_weapon_world_scene = weapon_item.get("world_item_scene")
			weapon_item.queue_free()
			return
		_equip_weapon_resource(resource)
	
	_current_weapon_world_scene = weapon_item.get("world_item_scene")
	_has_weapon = true
	weapon_master.visible = true
	weapon_item.queue_free()

func try_pick_up_weapon_resource(resource: WeaponResource, source: Node = null) -> bool:
	if resource == null:
		return false
	if weapon_inventory:
		return weapon_inventory.try_pick_up(resource, source)
	return _equip_weapon_resource(resource)

func _equip_weapon_resource(resource: WeaponResource) -> bool:
	if resource == null or weapon_master == null:
		return false
	current_weapon = resource
	weapon_master.set("weapon_resource", resource)
	if weapon_master.has_signal("fired"):
		if not weapon_master.fired.is_connected(_on_weapon_fired):
			weapon_master.fired.connect(_on_weapon_fired)
	_has_weapon = true
	weapon_master.visible = true
	return true

func _set_node_visible_recursive(node: Node, set_visible: bool) -> void:
	if node is Node3D:
		node.visible = set_visible
	if node is GeometryInstance3D:
		# Also handle internal visibility for geometry
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if set_visible else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_set_node_visible_recursive(child, set_visible)

func _force_node_render_recursive(node: Node) -> void:
	if node is Node3D:
		node.visible = true
	if node is VisualInstance3D:
		node.layers = 1 # Force to Layer 1 (Main)
	for child in node.get_children():
		_force_node_render_recursive(child)

func _check_interaction() -> void:
	# Use forward ray if available, otherwise use a small area check
	if forward_ray and forward_ray.is_colliding():
		var collider = forward_ray.get_collider()
		if _try_interact_with(collider):
			return
			
	# Fallback: check for overlapping objects in a small radius
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = PICKUP_QUERY_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self]
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var obj = result["collider"]
		if _try_interact_with(obj):
			return

	if _try_nearest_weapon_pickup():
		return

func _try_nearest_weapon_pickup() -> bool:
	var best_pickup: Node3D = null
	var best_distance_sq := INF
	var max_distance_sq := PICKUP_INTERACTION_RADIUS * PICKUP_INTERACTION_RADIUS
	for node in get_tree().get_nodes_in_group("weapon_pickups"):
		var pickup := node as Node3D
		if pickup == null or not is_instance_valid(pickup) or pickup.is_queued_for_deletion():
			continue
		var distance_sq := global_position.distance_squared_to(pickup.global_position)
		if distance_sq > max_distance_sq or distance_sq >= best_distance_sq:
			continue
		best_distance_sq = distance_sq
		best_pickup = pickup
	if best_pickup == null:
		return false
	return _try_interact_with(best_pickup)

func _try_interact_with(node: Node) -> bool:
	var current := node
	while current:
		if current != self and current.has_method("interact"):
			var result = current.interact(self)
			if result is bool:
				return result
			return true
		current = current.get_parent()
	return false

func _play_one_shot(animation_name: String) -> void:
	if _animation_player == null:
		return
	if not _animation_player.has_animation(animation_name):
		return
	if _one_shot_animation == animation_name and _animation_player.is_playing():
		return
	_one_shot_animation = animation_name
	_animation_player.play(animation_name)

func _on_animation_finished(animation_name: StringName) -> void:
	if String(animation_name) == _one_shot_animation:
		_one_shot_animation = ""

func play_state_animation(candidates: Array, fallback_candidates: Array = []) -> String:
	if _animation_player == null:
		return ""
	for animation_name in candidates:
		if _animation_player.has_animation(animation_name):
			_animation_player.play(animation_name)
			return animation_name
	for animation_name in fallback_candidates:
		if _animation_player.has_animation(animation_name):
			_animation_player.play(animation_name)
			return animation_name
	return ""

func lock_state_animation(candidates: Array, fallback_candidates: Array = []) -> String:
	var selected := play_state_animation(candidates, fallback_candidates)
	_state_animation_lock = selected
	return selected

func clear_state_animation_lock() -> void:
	_state_animation_lock = ""

func _ensure_animation_tree() -> AnimationTree:
	if animation_tree != null:
		return animation_tree
	if body_root == null:
		return null
	if _animation_player == null:
		return null
	animation_tree = body_root.get_node_or_null("AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = AnimationTree.new()
		animation_tree.name = "AnimationTree"
		body_root.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(_animation_player)
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_tree.active = false
	return animation_tree

func start_vault_root_motion(animation_name: String, duration: float) -> bool:
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return false
	var tree := _ensure_animation_tree()
	if tree == null:
		return false
	var node := AnimationNodeAnimation.new()
	node.animation = animation_name
	tree.tree_root = node
	tree.root_motion_track = NodePath("Armature/Skeleton3D:root")
	tree.active = true
	tree.advance(0.0)
	_vault_root_motion_active = true
	_vault_root_motion_time_left = duration
	var clip := _animation_player.get_animation(animation_name)
	if clip:
		_vault_root_motion_time_left = max(duration, clip.length)
	return true

func consume_vault_root_motion(delta: float) -> Vector3:
	if not _vault_root_motion_active or animation_tree == null:
		return Vector3.ZERO
	animation_tree.advance(delta)
	var delta_local: Vector3 = animation_tree.get_root_motion_position()
	var delta_world: Vector3 = global_transform.basis * delta_local
	_vault_root_motion_time_left -= delta
	if _vault_root_motion_time_left <= 0.0:
		stop_vault_root_motion()
	if delta <= 0.0:
		return Vector3.ZERO
	return delta_world / delta

func is_vault_root_motion_active() -> bool:
	return _vault_root_motion_active

func stop_vault_root_motion() -> void:
	_vault_root_motion_active = false
	_vault_root_motion_time_left = 0.0
	if animation_tree:
		animation_tree.active = false

func get_wall_run_animation() -> String:
	var preferred := [
		"parkour_pro/WallRun",
		"parkour_pro/Wall_Run",
		"parkour_pro/WallRun_Left",
		"parkour_pro/Wall_Run_Left",
		"parkour_pro/WallRun_Right",
		"parkour_pro/Wall_Run_Right",
		"parkour_pro/RunWall",
		"parkour_pro/Run_Wall",
		"parkour/WallRun",
		"parkour/Wall_Run",
		"parkour/WallRun_Left",
		"parkour/Wall_Run_Left",
		"parkour/WallRun_Right",
		"parkour/Wall_Run_Right",
		"parkour/RunWall",
		"parkour/Run_Wall",
	]
	var resolved := lock_state_animation(preferred, ["parkour_pro/ClimbUp_1m_RM", "ClimbUp_1m_RM", "Sprint", "Jog_Fwd", "Walk"])
	if resolved != "":
		return resolved
	if _animation_player == null:
		return ""
	for animation_name in _animation_player.get_animation_list():
		var lower_name := String(animation_name).to_lower()
		if lower_name.contains("wall") and (lower_name.contains("run") or lower_name.contains("climb")):
			_state_animation_lock = String(animation_name)
			_animation_player.play(_state_animation_lock)
			return _state_animation_lock
	return ""

func _get_origin_to_floor_offset(max_probe_distance: float = 3.5) -> float:
	if get_world_3d() == null:
		return 1.0
	var start := global_position + Vector3.UP * 0.2
	var end := global_position + Vector3.DOWN * max_probe_distance
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.has("position"):
		return max(0.0, global_position.y - hit["position"].y)
	return 1.0

func _get_character_height() -> float:
	var collider := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collider and collider.shape is CapsuleShape3D:
		return (collider.shape as CapsuleShape3D).height
	return 1.8

func _has_head_clearance_at(target_origin: Vector3, clearance_margin: float = 0.15) -> bool:
	if get_world_3d() == null:
		return true
	var offset := _get_origin_to_floor_offset()
	var base := target_origin - Vector3.UP * offset + Vector3.UP * 0.05
	var top := base + Vector3.UP * (offset + clearance_margin)
	var query := PhysicsRayQueryParameters3D.create(base, top)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _compute_vault_landing_target(ledge_top_point: Vector3, forward: Vector3, forward_push: float) -> Vector3:
	var landing := ledge_top_point + (forward * forward_push)
	landing.y += _get_origin_to_floor_offset() + 0.03
	return landing

func find_vault_target() -> Dictionary:
	if forward_ray == null or head_ray == null or ledge_ray == null:
		return {}
	forward_ray.force_raycast_update()
	head_ray.force_raycast_update()
	if not forward_ray.is_colliding():
		return {}

	var forward := (-global_transform.basis.z).normalized()
	var wall_point := forward_ray.get_collision_point()
	var result := {}
	var floor_y := global_position.y - _get_origin_to_floor_offset()
	var character_height := _get_character_height()
	var vault_min := character_height * VAULT_MIN_HEIGHT_RATIO
	var vault_max := character_height * VAULT_MAX_HEIGHT_RATIO
	var mantle_max := character_height * MANTLE_MAX_HEIGHT_RATIO

	if not head_ray.is_colliding():
		ledge_ray.global_position = wall_point + (forward * 0.45) + Vector3(0, 1.2, 0)
		ledge_ray.target_position = Vector3(0, -1.3, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var ledge_point := ledge_ray.get_collision_point()
			if ledge_ray.get_collision_normal().y < LEDGE_MIN_NORMAL_Y:
				return {}
			var obstacle_height := ledge_point.y - floor_y
			if obstacle_height < vault_min or obstacle_height > mantle_max:
				return {}
			var low_target := _compute_vault_landing_target(ledge_point, forward, 0.32 if obstacle_height <= vault_max else 0.18)
			if not _has_head_clearance_at(low_target, 0.2):
				return {}
			result["target_position"] = low_target
			if obstacle_height <= vault_max:
				result["duration"] = 0.46
				result["animation_candidates"] = ["parkour_pro/ClimbUp_1m", "parkour/ClimbUp_1m", "ClimbUp_1m", "Jump_Start", "Jump"]
				result["type"] = "vault"
			else:
				result["duration"] = 0.62
				result["animation_candidates"] = ["parkour_pro/NinjaJump_Start", "parkour/NinjaJump_Start", "NinjaJump_Start", "Jump_Start", "Jump"]
				result["type"] = "mantle"
			return result
	else:
		ledge_ray.global_position = wall_point + (forward * 0.6) + Vector3(0, 2.0, 0)
		ledge_ray.target_position = Vector3(0, -2.2, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var ledge_point_high := ledge_ray.get_collision_point()
			if ledge_ray.get_collision_normal().y < LEDGE_MIN_NORMAL_Y:
				return {}
			var obstacle_height_high := ledge_point_high.y - floor_y
			if obstacle_height_high < vault_max * 0.9 or obstacle_height_high > mantle_max:
				return {}
			var high_target := _compute_vault_landing_target(ledge_point_high, forward, 0.18)
			if not _has_head_clearance_at(high_target, 0.25):
				return {}
			result["target_position"] = high_target
			result["duration"] = 0.62
			result["animation_candidates"] = ["parkour_pro/NinjaJump_Start", "parkour/NinjaJump_Start", "NinjaJump_Start", "Jump_Start", "Jump"]
			result["type"] = "mantle"
			return result
	return {}

func _check_parkour() -> bool:
	if forward_ray == null or head_ray == null or ledge_ray == null:
		return false
	if not forward_ray.is_colliding():
		return false
	if not head_ray.is_colliding():
		var wall_pos = forward_ray.get_collision_point()
		ledge_ray.global_position = wall_pos + (-global_transform.basis.z * 0.5) + Vector3(0, 1.0, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var target_pos = ledge_ray.get_collision_point()
			_do_parkour_move(target_pos, "parkour/ClimbUp_1m")
			return true
	elif head_ray.is_colliding():
		ledge_ray.global_position = global_position + (-global_transform.basis.z * 0.8) + Vector3(0, 3.0, 0)
		ledge_ray.force_raycast_update()
		if ledge_ray.is_colliding():
			var mantle_target = ledge_ray.get_collision_point()
			_do_parkour_move(mantle_target, "parkour/NinjaJump_Start")
			return true
	return false

func _do_parkour_move(target_pos: Vector3, animation_name: String) -> void:
	_is_parkouring = true
	if _parkour_tween:
		_parkour_tween.kill()
	_parkour_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	var final_pos = target_pos + Vector3(0, 0.05, 0)
	_parkour_tween.tween_property(self, "global_position", final_pos, 0.8)
	_play_one_shot(animation_name)
	_parkour_tween.finished.connect(func():
		_is_parkouring = false
	)

func _toggle_ads(aiming: bool) -> void:
	if camera_node == null or spring_arm == null:
		return
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if aiming:
		_camera_tween.tween_property(camera_node, "fov", ADS_FOV, 0.2)
		_camera_tween.tween_property(spring_arm, "spring_length", ADS_SPRING_LENGTH, 0.2)
		_camera_tween.tween_property(camera_node, "h_offset", ADS_H_OFFSET, 0.2)
	else:
		_camera_tween.tween_property(camera_node, "fov", DEFAULT_FOV, 0.2)
		_camera_tween.tween_property(spring_arm, "spring_length", DEFAULT_SPRING_LENGTH, 0.2)
		_camera_tween.tween_property(camera_node, "h_offset", DEFAULT_H_OFFSET, 0.2)

func _get_move_input() -> Vector2:
	var input_direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_direction.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_direction.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_direction.y += 1.0
	return input_direction.normalized() if input_direction.length_squared() > 1.0 else input_direction

func _apply_weapon_recoil() -> void:
	if weapon_master == null:
		return
	_recoil_position_offset -= RECOIL_POSITION_KICK
	_recoil_rotation_offset += RECOIL_ROTATION_KICK

func _capture_debug_screenshot() -> void:
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var path: String = "user://screenshots/%s_%s.png" % [name, stamp]
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var err: int = img.save_png(path)
		if err == OK:
			print("DEBUG_SCREENSHOT_SAVED: ", path)
		else:
			push_warning("Screenshot save failed: %s" % path)

func _fire_projectile() -> void:
	if weapon_master == null:
		return
	var muzzle = weapon_master.get_node_or_null("Muzzle")
	if muzzle == null:
		return
	var direction := _get_projectile_direction(muzzle.global_position)
	var damage_val := current_weapon.damage if current_weapon else 1.0
	var speed_val := PROJECTILE_SPEED
	spawn_projectile.rpc(muzzle.global_position, direction, damage_val, speed_val)

func _get_projectile_direction(origin: Vector3) -> Vector3:
	if camera_node == null:
		return -global_transform.basis.z
	var viewport := get_viewport()
	if viewport == null:
		return -camera_node.global_transform.basis.z
	var view_center := viewport.get_visible_rect().size * 0.5
	var ray_origin := camera_node.project_ray_origin(view_center)
	var ray_direction := camera_node.project_ray_normal(view_center)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * PROJECTILE_RANGE)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = ray_origin + ray_direction * PROJECTILE_RANGE
	if hit.has("position"):
		target = hit["position"]
	return (target - origin).normalized()

@rpc("any_peer", "call_local")
func spawn_projectile(pos: Vector3, dir: Vector3, damage_val: float = 1.0, speed_val: float = PROJECTILE_SPEED) -> void:
	var projectile_scene_to_spawn := _get_projectile_scene()
	if projectile_scene_to_spawn == null:
		return
	var projectile = projectile_scene_to_spawn.instantiate()
	if projectile == null:
		return
	projectile.name = "Bullet"
	get_tree().current_scene.add_child(projectile)
	
	projectile.global_position = pos
	projectile.set("direction", dir)
	projectile.set("speed", speed_val)
	projectile.set("damage", damage_val)
	projectile.set("shooter", self)
	projectile.look_at(pos + dir, Vector3.UP)

func _get_projectile_scene() -> PackedScene:
	if current_weapon and current_weapon.projectile_scene:
		return current_weapon.projectile_scene
	return _projectile_scene

func is_running() -> bool:
	return Input.is_physical_key_pressed(KEY_SHIFT)

@rpc("any_peer", "reliable")
func change_nick(new_nick: String) -> void:
	if nickname:
		nickname.text = new_nick

func set_player_skin(_skin_name: String) -> void:
	pass

@rpc("any_peer", "reliable")
func display_chat_message(message: String) -> void:
	chat_label.text = message
	chat_label.show()
	await get_tree().create_timer(10.0).timeout
	chat_label.hide()

func _on_inventory_weapon_equipped(resource: WeaponResource) -> void:
	current_weapon = resource
	_has_weapon = resource != null
	if weapon_master == null and weapon_inventory:
		weapon_master = weapon_inventory.get_weapon_master()
	if weapon_master:
		weapon_master.visible = _has_weapon
		if weapon_master.has_signal("fired") and not weapon_master.fired.is_connected(_on_weapon_fired):
			weapon_master.fired.connect(_on_weapon_fired)

func _on_inventory_weapon_dropped(_resource: WeaponResource) -> void:
	current_weapon = null
	_has_weapon = false

func _on_weapon_fired(_resource: WeaponResource) -> void:
	_fire_projectile()
