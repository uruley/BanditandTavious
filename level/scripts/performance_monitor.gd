extends CanvasLayer

# Global Performance HUD & Logger
# Toggle with F9

const LOG_FILE_PATH := "user://performance_log.csv"
const UPDATE_INTERVAL := 0.5
const LOG_INTERVAL := 1.0

var is_visible := false
var is_logging := false
var log_timer := 0.0
var update_timer := 0.0

var label: Label
var panel: Panel

var log_buffer: Array[String] = []
var mutex := Mutex.new()

func _ready() -> void:
	layer = 128 # High layer to stay on top
	_setup_ui()
	_setup_custom_monitors()
	process_mode = PROCESS_MODE_ALWAYS
	hide()

func _setup_ui() -> void:
	var control = Control.new()
	control.name = "Control"
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	
	var p = Panel.new()
	p.name = "Panel"
	p.modulate = Color(0, 0, 0, 0.5)
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	p.custom_minimum_size = Vector2(320, 240)
	control.add_child(p)
	
	var l = Label.new()
	l.name = "Label"
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	l.offset_left = 10
	l.offset_top = 10
	control.add_child(l)
	
	panel = p
	label = l

func _setup_custom_monitors() -> void:
	# Custom monitor IDs should use slash delimiters for editor categorization
	if not Performance.has_custom_monitor("AI/Active_Actors"):
		Performance.add_custom_monitor("AI/Active_Actors", _get_ai_count)
	if not Performance.has_custom_monitor("Destruction/Active_Shards"):
		Performance.add_custom_monitor("Destruction/Active_Shards", _get_shard_count)

func _get_ai_count() -> float:
	return float(get_tree().get_nodes_in_group("bandit_ai_actor").size())

func _get_shard_count() -> float:
	# Assuming shards are in a specific group or we can count Rigids in a container
	# For now, we'll count RigidBody3D nodes that are not the main player/destructibles
	var count = 0
	# This is a bit slow for a monitor, so in a real 'pro' setup we'd track this in a manager
	# But for the stress test, we'll use a group
	return float(get_tree().get_nodes_in_group("shards").size())

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F9:
			is_visible = !is_visible
			visible = is_visible
			set_process(is_visible or is_logging)

func _process(delta: float) -> void:
	if is_visible:
		update_timer += delta
		if update_timer >= UPDATE_INTERVAL:
			update_timer = 0.0
			_update_display()
	
	if is_logging:
		log_timer += delta
		if log_timer >= LOG_INTERVAL:
			log_timer = 0.0
			_log_snapshot()

func _update_display() -> void:
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var physics = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var phys_objs = Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var vram = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0
	
	var text = "--- PERFORMANCE ---"
	text += "\nFPS: %d" % fps
	text += "\nPhysics: %.2f ms" % physics
	text += "\nDraw Calls: %d" % draw_calls
	text += "\nVisible Objects: %d" % objects
	text += "\nActive Physics: %d" % phys_objs
	text += "\nRAM: %.1f MB" % mem
	text += "\nVRAM: %.1f MB" % vram
	text += "\n\n--- CUSTOM ---"
	text += "\nAI Actors: %d" % _get_ai_count()
	text += "\nActive Shards: %d" % _get_shard_count()
	
	if is_logging:
		text += "\n\n[LOGGING ACTIVE]"
	
	label.text = text

func start_logging() -> void:
	if is_logging: return
	is_logging = true
	log_timer = 0.0
	
	# Write header if file doesn't exist
	if not FileAccess.file_exists(LOG_FILE_PATH):
		var f = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
		f.store_line("timestamp,fps,physics_ms,draw_calls,objects,phys_objs,mem_mb,vram_mb,ai_count,shard_count")
	
	_log_snapshot()
	set_process(true)

func stop_logging() -> void:
	is_logging = false
	_flush_logs()

func _log_snapshot() -> void:
	var timestamp = Time.get_datetime_string_from_system()
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var physics = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var phys_objs = Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var vram = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0
	var ai = _get_ai_count()
	var shards = _get_shard_count()
	
	var line = "%s,%d,%.3f,%d,%d,%d,%.2f,%.2f,%d,%d" % [
		timestamp, fps, physics, draw_calls, objects, phys_objs, mem, vram, ai, shards
	]
	
	mutex.lock()
	log_buffer.append(line)
	if log_buffer.size() >= 10:
		_flush_logs_internal()
	mutex.unlock()

func _flush_logs() -> void:
	mutex.lock()
	_flush_logs_internal()
	mutex.unlock()

func _flush_logs_internal() -> void:
	if log_buffer.is_empty(): return
	
	var f = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
	if not f:
		f = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	
	f.seek_end()
	for line in log_buffer:
		f.store_line(line)
	
	log_buffer.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_flush_logs()
