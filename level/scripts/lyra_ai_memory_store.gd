extends Node

@export var memory_path: String = "user://lyra_ai_memory.json"
@export var event_log_path: String = "user://lyra_ai_memory_events.jsonl"
@export var reset_on_start: bool = false

var _memory: Dictionary = {}
var _event_file: FileAccess


func _ready() -> void:
	add_to_group("lyra_ai_memory_store")
	if reset_on_start:
		_remove_file(memory_path)
		_remove_file(event_log_path)
	_load_memory()
	_open_event_log()
	_memory["session_count"] = int(_memory.get("session_count", 0)) + 1
	_memory["last_started_utc"] = Time.get_datetime_string_from_system(true)
	_save_memory("startup")
	print("AI_MEMORY loaded path=%s actors=%d session=%d" % [
		ProjectSettings.globalize_path(memory_path),
		_get_actors().size(),
		int(_memory.get("session_count", 0)),
	])


func _exit_tree() -> void:
	_save_memory("shutdown")
	if _event_file != null:
		_event_file.flush()
		_event_file.close()
		_event_file = null


func emit_status(metrics: Node) -> void:
	if metrics == null or not metrics.has_method("log_event"):
		return
	metrics.call("log_event", {
		"type": "ai_memory_loaded",
		"memory_path": ProjectSettings.globalize_path(memory_path),
		"event_log_path": ProjectSettings.globalize_path(event_log_path),
		"session_count": int(_memory.get("session_count", 0)),
		"actor_memory_count": _get_actors().size(),
		"loaded_actor_names": _get_actors().keys(),
	})


func register_actor(actor_name: String, role: String) -> Dictionary:
	var actor_memory := _actor_memory(actor_name)
	var had_prior_memory := int(actor_memory.get("spawn_count", 0)) > 0
	actor_memory["role"] = role
	actor_memory["spawn_count"] = int(actor_memory.get("spawn_count", 0)) + 1
	actor_memory["last_spawned_utc"] = Time.get_datetime_string_from_system(true)
	_actor_map()[actor_name] = actor_memory
	_save_memory("actor_registered")
	return actor_memory.duplicate(true) if had_prior_memory else {}


func record_event(event: Dictionary) -> void:
	var event_copy := event.duplicate(true)
	event_copy["memory_recorded_utc"] = Time.get_datetime_string_from_system(true)
	_append_event(event_copy)

	if not event.has("actor"):
		return
	var actor_name := str(event.get("actor", ""))
	if actor_name == "":
		return

	var actor_memory := _actor_memory(actor_name)
	actor_memory["role"] = str(event.get("role", actor_memory.get("role", "")))
	actor_memory["last_event_type"] = str(event.get("type", ""))
	actor_memory["last_goal"] = str(event.get("goal", actor_memory.get("last_goal", "")))
	actor_memory["last_target"] = str(event.get("target", actor_memory.get("last_target", "")))
	actor_memory["last_seen_utc"] = Time.get_datetime_string_from_system(true)
	actor_memory["last_run_id"] = str(event.get("run_id", actor_memory.get("last_run_id", "")))
	actor_memory["event_count"] = int(actor_memory.get("event_count", 0)) + 1

	match str(event.get("type", "")):
		"goal_selected":
			actor_memory["goal_selected_count"] = int(actor_memory.get("goal_selected_count", 0)) + 1
		"goal_completed":
			actor_memory["goal_completed_count"] = int(actor_memory.get("goal_completed_count", 0)) + 1
		"goal_failed":
			actor_memory["goal_failed_count"] = int(actor_memory.get("goal_failed_count", 0)) + 1
			actor_memory["last_failure_reason"] = str(event.get("reason", ""))
		"interaction_complete":
			_record_interaction(actor_memory, event)
		"shot_fired":
			actor_memory["shot_count"] = int(actor_memory.get("shot_count", 0)) + 1
			if str(event.get("result", "")) == "hit":
				actor_memory["shot_hit_count"] = int(actor_memory.get("shot_hit_count", 0)) + 1
		"route_visit":
			actor_memory["route_visit_count"] = int(actor_memory.get("route_visit_count", 0)) + 1
			actor_memory["last_waypoint"] = str(event.get("target", ""))
		"stuck":
			actor_memory["stuck_count"] = int(actor_memory.get("stuck_count", 0)) + 1

	_actor_map()[actor_name] = actor_memory
	_save_memory("event")


func _record_interaction(actor_memory: Dictionary, event: Dictionary) -> void:
	actor_memory["interaction_count"] = int(actor_memory.get("interaction_count", 0)) + 1
	if str(event.get("result", "")) == "success":
		actor_memory["successful_interaction_count"] = int(actor_memory.get("successful_interaction_count", 0)) + 1

	var delta: Variant = event.get("delta", {})
	if delta is Dictionary:
		if delta.has("weapon") and str(delta["weapon"]) != "" and str(delta["weapon"]) != "failed":
			actor_memory["weapon_pickup_count"] = int(actor_memory.get("weapon_pickup_count", 0)) + 1
			actor_memory["last_weapon"] = str(delta["weapon"])
		if delta.has("resource_count"):
			actor_memory["last_resource_delta"] = int(delta["resource_count"])
		if delta.has("waypoint"):
			actor_memory["last_waypoint"] = str(delta["waypoint"])
		if delta.has("build"):
			actor_memory["last_build_state"] = str(delta["build"])


func _load_memory() -> void:
	_memory = {
		"schema_version": 1,
		"session_count": 0,
		"actors": {},
	}
	if not FileAccess.file_exists(memory_path):
		return
	var file := FileAccess.open(memory_path, FileAccess.READ)
	if file == null:
		push_warning("Lyra AI memory could not read %s" % memory_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_memory = parsed
	if not _memory.has("actors") or not (_memory["actors"] is Dictionary):
		_memory["actors"] = {}


func _save_memory(reason: String) -> void:
	_memory["last_save_reason"] = reason
	_memory["last_saved_utc"] = Time.get_datetime_string_from_system(true)
	var absolute_path := ProjectSettings.globalize_path(memory_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(memory_path, FileAccess.WRITE)
	if file == null:
		push_warning("Lyra AI memory could not write %s" % memory_path)
		return
	file.store_string(JSON.stringify(_memory, "\t"))
	file.flush()


func _open_event_log() -> void:
	var absolute_path := ProjectSettings.globalize_path(event_log_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if FileAccess.file_exists(event_log_path):
		_event_file = FileAccess.open(event_log_path, FileAccess.READ_WRITE)
		if _event_file != null:
			_event_file.seek_end()
	else:
		_event_file = FileAccess.open(event_log_path, FileAccess.WRITE)
	if _event_file == null:
		push_warning("Lyra AI memory event log could not open %s" % event_log_path)


func _append_event(event: Dictionary) -> void:
	if _event_file == null:
		return
	_event_file.store_line(JSON.stringify(event))
	_event_file.flush()


func _actor_memory(actor_name: String) -> Dictionary:
	var actors := _actor_map()
	if actors.has(actor_name) and actors[actor_name] is Dictionary:
		return (actors[actor_name] as Dictionary).duplicate(true)
	return {
		"name": actor_name,
		"event_count": 0,
		"interaction_count": 0,
		"successful_interaction_count": 0,
		"goal_selected_count": 0,
		"goal_completed_count": 0,
		"goal_failed_count": 0,
		"weapon_pickup_count": 0,
		"shot_count": 0,
		"shot_hit_count": 0,
		"route_visit_count": 0,
		"stuck_count": 0,
	}


func _actor_map() -> Dictionary:
	if not _memory.has("actors") or not (_memory["actors"] is Dictionary):
		_memory["actors"] = {}
	return _memory["actors"]


func _get_actors() -> Dictionary:
	return _actor_map()


func _remove_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute_path)
