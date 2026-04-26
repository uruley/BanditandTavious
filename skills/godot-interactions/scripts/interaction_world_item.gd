extends RigidBody3D

@export var item_id: String = ""
@export var item_data: Dictionary = {}

func interact(player: Node3D) -> void:
	if player.has_method("on_interact_with_item"):
		player.on_interact_with_item(self)
