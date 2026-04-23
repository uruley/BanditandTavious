extends SceneTree

func _init():
	var libs = ["res://assets/animations/parkour_pro.res", "res://assets/animations/locomotion_base.res"]
	for lib_path in libs:
		if FileAccess.file_exists(lib_path):
			var lib = load(lib_path)
			if lib is AnimationLibrary:
				print("LIB_START: ", lib_path)
				for anim_name in lib.get_animation_list():
					print("ANIM: ", anim_name)
				print("LIB_END")
	quit()
