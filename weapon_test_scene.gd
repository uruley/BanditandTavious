extends Node3D

func _ready() -> void:
	var player_scene = load("res://level/scenes/lyra_player_clean.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		add_child(player)
		player.global_position = Vector3(0, 1, 0)
		player.set_multiplayer_authority(1) # For local testing
		
	var weapon_scene = load("res://WeaponWorldItem.tscn")
	if weapon_scene:
		var weapon = weapon_scene.instantiate()
		add_child(weapon)
		weapon.global_position = Vector3(2, 0.5, -2)
		
	var silver_weapon_scene = load("res://SilverWeaponWorldItem.tscn")
	if silver_weapon_scene:
		var silver_weapon = silver_weapon_scene.instantiate()
		add_child(silver_weapon)
		silver_weapon.global_position = Vector3(-2, 0.5, -2)
