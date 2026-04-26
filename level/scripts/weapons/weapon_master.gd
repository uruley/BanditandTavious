@tool
extends Node3D

@export var weapon_resource: WeaponResource:
	set(value):
		weapon_resource = value
		if is_node_ready():
			update_weapon_visuals()
@export var auto_update_in_editor := true

@onready var visual_container: Node3D = $VisualContainer
@onready var muzzle: Marker3D = $Muzzle
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var cooldown_timer: Timer = $CooldownTimer

signal fired(weapon_resource: WeaponResource)

var _current_visuals_scene: PackedScene = null

func _ready() -> void:
	if not Engine.is_editor_hint():
		# Hide editor guides at runtime
		for child in get_children():
			if "Guide" in child.name:
				child.visible = false
				
	if weapon_resource:
		update_weapon_visuals()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not auto_update_in_editor:
		return
	if weapon_resource == null:
		return
	if weapon_resource.weapon_visuals != _current_visuals_scene:
		update_weapon_visuals()
	else:
		_apply_weapon_alignment()

func update_weapon_visuals() -> void:
	# Clear existing visuals
	for child in visual_container.get_children():
		visual_container.remove_child(child)
		child.queue_free()
	_current_visuals_scene = null
	
	if not weapon_resource or not weapon_resource.weapon_visuals:
		_apply_weapon_alignment()
		return
	
	# Instantiate new visuals
	var visuals = weapon_resource.weapon_visuals.instantiate()
	visual_container.add_child(visuals)
	_current_visuals_scene = weapon_resource.weapon_visuals
	
	_apply_weapon_alignment()
	
	if weapon_resource.fire_sound:
		audio_player.stream = weapon_resource.fire_sound
	
	cooldown_timer.wait_time = weapon_resource.fire_rate

func _apply_weapon_alignment() -> void:
	if visual_container == null:
		return
	if weapon_resource == null:
		visual_container.position = Vector3.ZERO
		visual_container.rotation_degrees = Vector3.ZERO
		visual_container.scale = Vector3.ONE
		return
	visual_container.position = weapon_resource.position_offset
	visual_container.rotation_degrees = weapon_resource.rotation_offset
	visual_container.scale = weapon_resource.scale_offset
	if muzzle:
		muzzle.position = weapon_resource.muzzle_position_offset
		muzzle.rotation_degrees = weapon_resource.muzzle_rotation_offset

func fire() -> bool:
	if not weapon_resource or not cooldown_timer.is_stopped():
		return false
	
	# Start cooldown
	cooldown_timer.start()
	
	# Play Sound
	if audio_player.stream:
		audio_player.play()
	
	# VFX
	if weapon_resource.muzzle_vfx:
		var vfx = weapon_resource.muzzle_vfx.instantiate()
		muzzle.add_child(vfx)
	
	# Projectile or Signal
	fired.emit(weapon_resource)
	
	return true
