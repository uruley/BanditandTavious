extends Node3D

const PLAYER_SCENE := preload("res://level/scenes/godot_manny_player.tscn")


func _ready() -> void:
	if has_node("Player"):
		return

	var player := PLAYER_SCENE.instantiate()
	player.name = "Player"

	var spawn_marker := get_node_or_null("PlayerSpawn") as Node3D
	if spawn_marker != null:
		player.global_position = spawn_marker.global_position
	else:
		player.position = Vector3(0.0, 1.25, 0.0)

	add_child(player)
