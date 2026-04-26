@tool
extends Node3D

func _ready() -> void:
	if get_child_count() == 0 or (get_child_count() == 1 and get_child(0).name == "A3500X_silver_rigged" and get_child(0).get_child_count() == 0):
		var glb = load("res://assets/weapons/A3500X_silver_rigged.glb")
		if glb:
			var model = glb.instantiate()
			# Remove placeholder if it exists
			if has_node("A3500X_silver_rigged"):
				get_node("A3500X_silver_rigged").queue_free()
			add_child(model)
			model.name = "Model"
			# Apply any necessary offsets for the rifle
			model.rotation_degrees = Vector3(0, 180, 0) # Adjust if it's facing the wrong way
