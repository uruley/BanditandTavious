extends Node3D

@export var vehicle_scene: PackedScene = preload("res://level/scenes/vehicles/BoxCarPropeller.tscn")
@export var auto_drive_for_preview := true
@export var verification_seconds := 1.5
@export var screenshot_path := "res://logs/box_car_propeller_test.png"

@onready var camera: Camera3D = $Camera3D

var vehicle: Node3D
var verification_enabled := false
var verification_elapsed := 0.0
var verification_finishing := false

func _ready() -> void:
	verification_enabled = OS.get_cmdline_user_args().has("--vehicle-test")
	vehicle = vehicle_scene.instantiate()
	vehicle.name = "BoxCarPropeller"
	add_child(vehicle)
	vehicle.global_position = Vector3(0.0, 0.75, 0.0)
	vehicle.set("auto_drive", auto_drive_for_preview or verification_enabled)
	if verification_enabled:
		vehicle.set("auto_drive_speed", 4.0)

func _process(delta: float) -> void:
	if vehicle == null:
		return

	camera.global_position = vehicle.global_position + Vector3(0.0, 4.5, 8.0)
	camera.look_at(vehicle.global_position + Vector3(0.0, 0.7, 0.0), Vector3.UP)

	if verification_enabled:
		verification_elapsed += delta
	if verification_enabled and not verification_finishing:
		if verification_elapsed >= verification_seconds:
			_finish_verification()
	elif verification_enabled and verification_elapsed >= verification_seconds + 3.0:
		print("VEHICLE_TEST: timed out while finishing verification")
		get_tree().quit(1)

func _finish_verification() -> void:
	verification_finishing = true

	var save_error := ERR_UNAVAILABLE
	if DisplayServer.get_name() != "headless":
		var viewport_texture := get_viewport().get_texture()
		if viewport_texture != null:
			var image := viewport_texture.get_image()
			if image != null:
				save_error = image.save_png(screenshot_path)

	var spin_totals: Dictionary = vehicle.call("get_visual_spin_totals")
	var speed: float = vehicle.call("get_forward_speed")
	var motion_passed := absf(speed) > 0.1 and float(spin_totals.get("wheel", 0.0)) > 0.1 and float(spin_totals.get("propeller", 0.0)) > 0.1
	var screenshot_saved := save_error == OK

	print("VEHICLE_TEST: speed=", speed, " wheel_spin=", spin_totals.get("wheel", 0.0), " propeller_spin=", spin_totals.get("propeller", 0.0), " screenshot=", ProjectSettings.globalize_path(screenshot_path), " save_error=", save_error, " screenshot_saved=", screenshot_saved, " motion_passed=", motion_passed)
	get_tree().quit(0 if motion_passed else 1)
