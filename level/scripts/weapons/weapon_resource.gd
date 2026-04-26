extends Resource
class_name WeaponResource

@export var weapon_name: String = "Weapon"
@export var weapon_visuals: PackedScene

@export_category("Hand Alignment")
@export var position_offset: Vector3 = Vector3.ZERO
@export var rotation_offset: Vector3 = Vector3.ZERO
@export var scale_offset: Vector3 = Vector3.ONE

@export_category("Muzzle Alignment")
@export var muzzle_position_offset: Vector3 = Vector3.ZERO
@export var muzzle_rotation_offset: Vector3 = Vector3.ZERO

@export_category("Stats")
@export var damage: float = 10.0
@export var fire_rate: float = 0.5
@export var mag_size: int = 10
@export var is_automatic: bool = false

@export_category("Effects")
@export var fire_sound: AudioStream
@export var muzzle_vfx: PackedScene
@export var projectile_scene: PackedScene # If null, use Raycast
