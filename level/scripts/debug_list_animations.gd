extends MainLoop

func _process(_delta: float) -> bool:
	var parkour_lib_path := "res://assets/animations/parkour_pro.res"
	if FileAccess.file_exists(parkour_lib_path):
		var lib = load(parkour_lib_path)
		if lib is AnimationLibrary:
			print("ANIM_LIST_START")
			for anim_name in lib.get_animation_list():
				print("ANIM: ", anim_name)
			print("ANIM_LIST_END")
		else:
			print("ERROR: Loaded object is not an AnimationLibrary")
	else:
		print("ERROR: File not found: ", parkour_lib_path)
	return true
