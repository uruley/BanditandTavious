extends Node

@export var enabled: bool = true
@export var sample_interval_seconds: float = 1.0
@export var output_path: String = "user://bandit_ai_activity.jsonl"

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	if not enabled:
		return

	_elapsed += delta
	if _elapsed < sample_interval_seconds:
		return
	_elapsed = 0.0

	_write_snapshot()


func _write_snapshot() -> void:
	var now_ms := Time.get_ticks_msec()
	var actors: Array = get_tree().get_nodes_in_group("bandit_ai_actor")
	var samples: Array = []

	for actor in actors:
		if actor.has_method("get_ai_snapshot"):
			samples.append(actor.get_ai_snapshot())
		else:
			samples.append({
				"name": actor.name,
				"position": actor.global_position if actor is Node3D else Vector3.ZERO,
			})

	var payload := {
		"timestamp_ms": now_ms,
		"scene": get_tree().current_scene.name if get_tree().current_scene else "",
		"actors": samples,
	}

	var file: FileAccess
	if FileAccess.file_exists(output_path):
		file = FileAccess.open(output_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(output_path, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open AI activity log file: %s" % output_path)
		return

	file.store_line(JSON.stringify(payload))
	file.close()
