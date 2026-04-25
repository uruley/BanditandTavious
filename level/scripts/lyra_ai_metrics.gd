extends Node

@export var run_id: String = "lyra_ai_phase1"
@export var metrics_path: String = "res://logs/ai_metrics.jsonl"

var _file: FileAccess


func _ready() -> void:
	add_to_group("lyra_ai_metrics")
	var absolute_path := ProjectSettings.globalize_path(metrics_path)
	var absolute_dir := absolute_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(absolute_dir)
	if FileAccess.file_exists(metrics_path):
		DirAccess.remove_absolute(absolute_path)
	_file = FileAccess.open(metrics_path, FileAccess.WRITE)
	if _file == null:
		push_warning("Lyra AI metrics could not open %s" % metrics_path)


func _exit_tree() -> void:
	if _file != null:
		_file.flush()
		_file.close()
		_file = null


func log_event(event: Dictionary) -> void:
	event["run_id"] = run_id
	event["scene"] = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	event["time_sec"] = Time.get_ticks_msec() * 0.001
	event["frame"] = Engine.get_physics_frames()

	var line := JSON.stringify(event)
	print("AI_METRIC ", line)
	if _file == null:
		return
	_file.store_line(line)
	_file.flush()
