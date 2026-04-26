@tool
extends "res://weapon_world_item.gd"

func _init() -> void:
	weapon_id = "silver_rifle"
	weapon_resource = load("res://level/data/weapons/rifle.tres")
	world_item_scene = load("res://SilverWeaponWorldItem.tscn")
	weapon_visual_scene = load("res://SilverRifle.tscn")
