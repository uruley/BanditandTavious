class_name PlayerVault
extends PlayerState

const VAULT_MAX_SPEED := 8.0

var _target_position := Vector3.ZERO
var _vault_duration := 0.5
var _is_vaulting := false
var _is_grounding := false
var _grounding_frames := 0
var _vault_tween: Tween
var _collision_shape: CollisionShape3D = null
var _capsule_shape: CapsuleShape3D = null
var _capsule_height_before := 0.0
var _collision_y_before := 0.0
var _collision_mask_before := 0
var _collision_layer_before := 0
var _collision_disabled_during_vault := false

func enter(msg := {}) -> void:
	_target_position = msg.get("target_position", player.global_position) as Vector3
	_vault_duration = float(msg.get("duration", 0.5))
	var animation_candidates: Array = msg.get("animation_candidates", []) as Array
	var prioritized_candidates := _prioritize_traversal_animations(animation_candidates)
	
	_collision_mask_before = player.collision_mask
	_collision_layer_before = player.collision_layer
	
	# Become a "ghost" but keep the shape active
	player.collision_mask = 0
	player.collision_layer = 0
	_collision_disabled_during_vault = true
	
	player.velocity = Vector3.ZERO
	_configure_climb_collision(true)
	player.lock_state_animation(prioritized_candidates, ["Jump_Start", "Jump"])
	_start_vault_tween()

func exit() -> void:
	if _vault_tween:
		_vault_tween.kill()
	_vault_tween = null
	player.stop_vault_root_motion()
	_is_vaulting = false
	_is_grounding = false
	_grounding_frames = 0
	_configure_climb_collision(false)
	_restore_post_vault_collision()
	player.clear_state_animation_lock()

func physics_update(_delta: float) -> void:
	if _is_vaulting:
		# Procedural vaulting using physics (capsule and mesh stay coupled).
		var to_target := _target_position - player.global_position
		var distance := to_target.length()
		
		if distance < 0.15:
			if _vault_tween:
				_vault_tween.kill()
				_vault_tween = null
			_finish_vault()
			return
		
		var desired_velocity: Vector3 = to_target / maxf(_delta, 0.001)
		player.velocity = desired_velocity.limit_length(VAULT_MAX_SPEED)
		player.move_and_slide()
		return

	if _is_grounding:
		_grounding_frames += 1
		player.apply_floor_snap()
		if not player.is_on_floor():
			player.velocity = Vector3(0.0, -8.0, 0.0)
			player.move_and_slide()
			player.apply_floor_snap()
		if not player.is_on_floor() and _grounding_frames < 8:
			return
		_is_grounding = false
		player.velocity = Vector3.ZERO
	if not player.is_on_floor():
		player.velocity = Vector3(0.0, -8.0, 0.0)
		player.move_and_slide()
		if not player.is_on_floor():
			return
	player.velocity = Vector3.ZERO
	var move_dir := player.get_move_direction()
	if move_dir.length_squared() > 0.01:
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")

func _start_vault_tween() -> void:
	_is_vaulting = true
	if _vault_tween:
		_vault_tween.kill()
	_vault_tween = null

func _finish_vault() -> void:
	if not _is_vaulting:
		return
	_is_vaulting = false
	if _vault_tween:
		_vault_tween.kill()
		_vault_tween = null

	_restore_post_vault_collision()
	player.velocity = Vector3.ZERO

	# Final grounding pass: probe down and place body origin using the current floor offset.
	var offset_to_floor: float = player._get_origin_to_floor_offset()
	var start: Vector3 = player.global_position + Vector3.UP * 0.35
	var end: Vector3 = player.global_position + Vector3.DOWN * 4.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [player]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.has("position") and hit.has("normal") and hit["normal"].y >= 0.45:
		player.global_position.y = hit["position"].y + offset_to_floor

	player.apply_floor_snap()
	if not player.is_on_floor():
		player.velocity.y = -8.0
		player.move_and_slide()
		player.apply_floor_snap()

	_is_grounding = true
	_grounding_frames = 0

func _restore_post_vault_collision() -> void:
	if not _collision_disabled_during_vault:
		return
	player.collision_mask = _collision_mask_before
	player.collision_layer = _collision_layer_before
	_collision_disabled_during_vault = false

func _configure_climb_collision(enabled: bool) -> void:
	if _collision_shape == null:
		_collision_shape = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape == null:
		return
	if _capsule_shape == null:
		_capsule_shape = _collision_shape.shape as CapsuleShape3D
		if _capsule_shape:
			_collision_shape.shape = _capsule_shape.duplicate()
			_capsule_shape = _collision_shape.shape as CapsuleShape3D
	if _capsule_shape == null:
		return
	if enabled:
		_capsule_height_before = _capsule_shape.height
		_collision_y_before = _collision_shape.position.y
		_capsule_shape.height = max(0.5, _capsule_height_before * 0.84)
		_collision_shape.position.y = _collision_y_before - ((_capsule_height_before - _capsule_shape.height) * 0.5)
	else:
		if _capsule_height_before > 0.0:
			_capsule_shape.height = _capsule_height_before
		_collision_shape.position.y = _collision_y_before

func _prioritize_traversal_animations(candidates: Array) -> Array:
	var prioritized: Array = []
	for candidate in candidates:
		var clip := String(candidate)
		if clip.ends_with("_RM"):
			var non_root_clip := clip.trim_suffix("_RM")
			if not prioritized.has(non_root_clip):
				prioritized.append(non_root_clip)
	for candidate in candidates:
		var clip := String(candidate)
		if not prioritized.has(clip):
			prioritized.append(clip)
	return prioritized
