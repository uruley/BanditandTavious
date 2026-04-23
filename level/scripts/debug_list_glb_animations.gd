extends SceneTree

func _init():
	var glb_path = "res://assets/animations/quaternius/Unreal-Godot/UAL2_Standard.glb"
	if FileAccess.file_exists(glb_path):
		var glb = load(glb_path)
		if glb is PackedScene:
			var instance = glb.instantiate()
			var anim_player = instance.find_child("AnimationPlayer", true, false)
			if anim_player:
				print("GLB_START: ", glb_path)
				for anim_name in anim_player.get_animation_list():
					print("ANIM: ", anim_name)
				print("GLB_END")
	quit()
