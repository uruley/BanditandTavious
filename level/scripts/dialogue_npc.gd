extends Node3D

## Reads dialogue.json and plays exchanges between two Spartan warriors.
## Reloads the file each cycle so the coach's rewrites are picked up live.

@export var dialogue_path: String = "res://dialogue.json"
@export var line_hold_seconds: float = 4.0
@export var pause_between_cycles: float = 3.0

@onready var label_a: Label3D = $LeonidaLabel
@onready var label_b: Label3D = $DienekesLabel

var exchanges: Array = []
var current_index: int = 0
var timer: float = 0.0
var pausing: bool = false
var current_version: int = -1


func _ready() -> void:
	_load_dialogue()


func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return

	if pausing:
		pausing = false
		_load_dialogue()
		current_index = 0
		_show_line()
		return

	current_index += 1
	if current_index >= exchanges.size():
		label_a.text = ""
		label_b.text = ""
		pausing = true
		timer = pause_between_cycles
		return

	_show_line()


func _load_dialogue() -> void:
	var path := ProjectSettings.globalize_path(dialogue_path)
	if not FileAccess.file_exists(dialogue_path):
		# fall back to absolute path beside the project
		path = "C:/Users/ruley/AppData/Roaming/Godot/app_userdata/BanditandTavious/dialogue.json"

	var file := FileAccess.open(dialogue_path, FileAccess.READ)
	if file == null:
		return

	var parsed = JSON.parse_string(file.read_as_text())
	file.close()

	if not parsed is Dictionary:
		return

	var version: int = int(parsed.get("version", 1))
	if version != current_version:
		exchanges = parsed.get("exchanges", [])
		current_version = version
		print("[Dialogue] Loaded v%d — %d exchanges" % [version, exchanges.size()])


func _show_line() -> void:
	if current_index >= exchanges.size():
		return

	var entry: Dictionary = exchanges[current_index]
	var speaker: String = entry.get("speaker", "")
	var line: String = entry.get("line", "")

	if speaker == "leonidas":
		label_a.text = line
		label_b.text = ""
	else:
		label_a.text = ""
		label_b.text = line

	timer = line_hold_seconds
