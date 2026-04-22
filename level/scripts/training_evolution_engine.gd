extends Node

@export var mutation_rate: float = 0.15
@export var population_size: int = 3
@export var log_path: String = "user://evolution_log.jsonl"
@export var suggestions_path: String = "user://evolution_suggestions.json"

var generation: int = 0
var populations: Dictionary = {}
var pending_scores: Dictionary = {}

const BASE_PARAMS := {
	"enemy": {"move_speed": 3.6, "detection_range": 9.0, "wander_radius": 2.5, "shoot_cooldown": 1.5, "shoot_spread": 0.08},
	"citizen": {"move_speed": 2.6, "detection_range": 6.5, "wander_radius": 4.0},
	"companion": {"move_speed": 3.4, "detection_range": 8.0, "wander_radius": 2.0, "shoot_cooldown": 1.2, "shoot_spread": 0.06},
}

const PARAM_RANGES := {
	"move_speed": [1.0, 7.0],
	"detection_range": [3.0, 16.0],
	"wander_radius": [1.0, 8.0],
	"shoot_cooldown": [0.4, 4.0],
	"shoot_spread": [0.0, 0.25],
}


func _ready() -> void:
	for role in BASE_PARAMS:
		populations[role] = []
		for i in population_size:
			var params: Dictionary = BASE_PARAMS[role].duplicate()
			if i > 0:
				params = _mutate(params)
			populations[role].append(params)


func get_params(role: String, index: int) -> Dictionary:
	if role not in populations:
		return {}
	return populations[role][index % populations[role].size()].duplicate()


func record_score(role: String, index: int, score: float) -> void:
	pending_scores["%s_%d" % [role, index]] = score


func evolve() -> void:
	generation += 1
	var log_entry := {
		"generation": generation,
		"timestamp_ms": Time.get_ticks_msec(),
		"roles": {},
	}

	for role in populations:
		var pop: Array = populations[role]
		var scored: Array = []

		for i in pop.size():
			var key := "%s_%d" % [role, i]
			scored.append({"params": pop[i], "score": pending_scores.get(key, 0.0)})

		scored.sort_custom(func(a, b): return a["score"] > b["score"])

		log_entry["roles"][role] = {
			"scores": scored.map(func(s): return s["score"]),
			"best_params": scored[0]["params"],
		}

		var elite: Dictionary = scored[0]["params"].duplicate()
		var coach_params := _read_coach_suggestion(role)
		if not coach_params.is_empty():
			elite = coach_params
			log_entry["roles"][role]["coach_override"] = true

		var new_pop: Array = [elite]
		for i in range(1, pop.size()):
			new_pop.append(_mutate(elite.duplicate()))
		populations[role] = new_pop

	pending_scores.clear()
	_consume_coach_suggestions()
	_write_log(log_entry)
	print("[Evolution] Gen %d done — best enemy: %.1f  citizen: %.1f  companion: %.1f" % [
		generation,
		log_entry["roles"].get("enemy", {}).get("scores", [0.0])[0],
		log_entry["roles"].get("citizen", {}).get("scores", [0.0])[0],
		log_entry["roles"].get("companion", {}).get("scores", [0.0])[0],
	])


func _mutate(params: Dictionary) -> Dictionary:
	var out := params.duplicate()
	for key in out:
		if key not in PARAM_RANGES:
			continue
		var r: Array = PARAM_RANGES[key]
		var delta: float = float(out[key]) * randf_range(-mutation_rate, mutation_rate)
		out[key] = clampf(float(out[key]) + delta, r[0], r[1])
	return out


var _cached_suggestions: Dictionary = {}

func _read_coach_suggestion(role: String) -> Dictionary:
	if _cached_suggestions.is_empty() and FileAccess.file_exists(suggestions_path):
		var file := FileAccess.open(suggestions_path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.read_as_text())
			file.close()
			if parsed is Dictionary:
				_cached_suggestions = parsed
				print("[Evolution] Coach suggestions loaded")
	return _cached_suggestions.get(role, {})


func _consume_coach_suggestions() -> void:
	if not _cached_suggestions.is_empty():
		_cached_suggestions.clear()
		if FileAccess.file_exists(suggestions_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(suggestions_path))


func _write_log(entry: Dictionary) -> void:
	var file: FileAccess
	if FileAccess.file_exists(log_path):
		file = FileAccess.open(log_path, FileAccess.READ_WRITE)
		if file:
			file.seek_end()
	else:
		file = FileAccess.open(log_path, FileAccess.WRITE)
	if file == null:
		push_error("Evolution engine: cannot write log to %s" % log_path)
		return
	file.store_line(JSON.stringify(entry))
	file.close()
