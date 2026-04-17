extends Node3D
class_name SpringArmCharacter

const MOUSE_SENSIBILITY: float = 0.005
const JOY_SENSIBILITY: float = 0.03

@export_category("Objects")
@export var _spring_arm: SpringArm3D = null

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	var joy_look = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if joy_look.length() > 0:
		rotate_y(-joy_look.x * JOY_SENSIBILITY)
		_spring_arm.rotate_x(-joy_look.y * JOY_SENSIBILITY)
		_spring_arm.rotation.x = clamp(_spring_arm.rotation.x, -PI/4, PI/24)

func _unhandled_input(_event) -> void:
	if (_event is InputEventMouseMotion) and is_multiplayer_authority():
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):  # Check if the right mouse button is pressed
			rotate_y(-_event.relative.x * MOUSE_SENSIBILITY)
			_spring_arm.rotate_x(-_event.relative.y * MOUSE_SENSIBILITY)
			_spring_arm.rotation.x = clamp(_spring_arm.rotation.x, -PI/4, PI/24)
