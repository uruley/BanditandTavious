extends Node3D

@export var hand_offset := Vector3(0, 0, 0.05)
@export var hand_rotation_degrees := Vector3(0, 180, 0)

func _ready() -> void:
	# Apply initial rotation if needed
	rotation_degrees = hand_rotation_degrees

func get_hand_offset() -> Vector3:
	return hand_offset
