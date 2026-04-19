extends Node3D

@onready var skin_input: LineEdit = $Menu/MainContainer/MainMenu/Option2/SkinInput
@onready var nick_input: LineEdit = $Menu/MainContainer/MainMenu/Option1/NickInput
@onready var room_input: LineEdit = $Menu/MainContainer/MainMenu/Option5/RoomInput
@onready var ip_input: LineEdit = $Menu/MainContainer/MainMenu/Option6/IPInput
@onready var players_container: Node3D = $PlayersContainer
@onready var menu: Control = $Menu
@onready var chair: Node3D = $Chair
@export var player_scene: PackedScene

# multiplayer chat
@onready var message: LineEdit = $MultiplayerChat/Message
@onready var send: Button = $MultiplayerChat/Send
@onready var chat: TextEdit = $MultiplayerChat/Chat
@onready var chat_title: Label = $MultiplayerChat/ChatTitle
@onready var multiplayer_chat: Control = $MultiplayerChat
var chat_visible = false
var join_in_progress = false
const SPAWN_OFFSET := Vector3(1.5, 0.05, 0.0)
const FLIGHT_PAD_OFFSET := Vector3(4.0, 0.35, 0.0)
const AUDIO_TEST_DURATION := 0.35
const AUDIO_TEST_FREQUENCY := 660.0
var _audio_test_player: AudioStreamPlayer = null

func _get_room_number() -> int:
	var room_text = room_input.text.strip_edges()
	if room_text == "":
		return 1
	return max(room_text.to_int(), 1)

func _get_room_port() -> int:
	var room_number = _get_room_number()
	return 8080 + room_number

func _get_server_ip() -> String:
	var server_ip = ip_input.text.strip_edges()
	if server_ip == "":
		return ip_input.placeholder_text
	return server_ip

func _ready():
	# multiplayer_chat.hide()

	message.hide()	
	send.hide()
	chat.hide()
	chat_title.hide()

	menu.show()
	multiplayer_chat.set_process_input(true)
	_ensure_flight_pad()
	_ensure_audio_test_player()
	
	Network.connect("player_connected", Callable(self, "_on_player_connected"))
	Network.connect("connected_ok", Callable(self, "_on_connected_ok"))
	Network.connect("connection_failed", Callable(self, "_on_connection_failed"))
	Network.connect("server_disconnected", Callable(self, "_on_server_disconnected"))
	multiplayer.peer_disconnected.connect(_remove_player)
	
func _on_player_connected(peer_id, player_info):
	print("DEBUG: _on_player_connected called for peer: ", peer_id)
	if multiplayer.is_server():
		for id in Network.players.keys():
			var player_data = Network.players[id]
			if id != peer_id:
				rpc_id(peer_id, "sync_player_skin", id, player_data["skin"])
				
		_add_player(peer_id, player_info)

func _ensure_flight_pad() -> void:
	if has_node("FlightPad"):
		return

	var flight_pad := StaticBody3D.new()
	flight_pad.name = "FlightPad"
	flight_pad.position = chair.position + FLIGHT_PAD_OFFSET if is_instance_valid(chair) else Vector3(6.5, 0.35, 12.58)
	add_child(flight_pad)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PadMesh"
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(2.4, 0.4, 2.4)
	mesh_instance.mesh = pad_mesh
	var pad_material := StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.18, 0.52, 0.92, 1.0)
	pad_material.emission_enabled = true
	pad_material.emission = Color(0.08, 0.22, 0.45, 1.0)
	mesh_instance.material_override = pad_material
	flight_pad.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.4, 0.4, 2.4)
	collision.shape = box_shape
	flight_pad.add_child(collision)

	var mount_point := Node3D.new()
	mount_point.name = "MountPoint"
	mount_point.position = Vector3(0.0, 1.05, 0.0)
	flight_pad.add_child(mount_point)

	var label := Label3D.new()
	label.name = "Hint"
	label.position = Vector3(0.0, 1.4, 0.0)
	label.text = "Press E to Fly"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1, 1, 1, 1)
	flight_pad.add_child(label)

func _ensure_audio_test_player() -> void:
	if _audio_test_player != null:
		return
	_audio_test_player = AudioStreamPlayer.new()
	_audio_test_player.name = "AudioTestPlayer"
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = AudioServer.get_mix_rate()
	stream.buffer_length = 0.5
	_audio_test_player.stream = stream
	add_child(_audio_test_player)

func _play_audio_test_tone() -> void:
	_ensure_audio_test_player()
	if not _audio_test_player.playing:
		_audio_test_player.play()
	var playback := _audio_test_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	playback.clear_buffer()
	var frame_count := int(AudioServer.get_mix_rate() * AUDIO_TEST_DURATION)
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	for i in frame_count:
		var sample := sin(TAU * AUDIO_TEST_FREQUENCY * float(i) / AudioServer.get_mix_rate()) * 0.25
		frames[i] = Vector2(sample, sample)
	playback.push_buffer(frames)

func _add_player(id: int, player_info : Dictionary):
	print("DEBUG: Attempting to _add_player: ", id)
	if players_container.has_node(str(id)): 
		print("DEBUG: Player already exists in container: ", id)
		return
	if not multiplayer.is_server(): 
		print("DEBUG: Skipping spawn (not server): ", id)
		return
		
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = get_spawn_point()
	player.set("_respawn_point", player.position)
	players_container.add_child(player, true)
	
	var nick = Network.players[id]["nick"]
	player.rpc("change_nick", nick)
	
	var skin_name = player_info["skin"]
	rpc("sync_player_skin", id, skin_name)
	
	rpc("sync_player_position", id, player.position)

func _on_host_pressed():
	menu.hide()
	multiplayer_chat.hide()
	join_in_progress = false
	var room_port = _get_room_port()  # Room 1 -> Port 8081, Room 2 -> Port 8082
	print("DEBUG: Host selected room ", _get_room_number(), " port=", room_port)
	var error = Network.start_host(room_port)
	if error != OK:
		menu.show()
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_single_player_pressed():
	_on_host_pressed()

func _on_join_pressed():
	if join_in_progress:
		return
	print("DEBUG: Join pressed, attempting connection...")
	join_in_progress = true
	message.hide()	
	send.hide()
	chat.hide()
	chat_title.hide()

	var room_port = _get_room_port()  # Room 1 -> Port 8081, Room 2 -> Port 8082
	var server_ip = _get_server_ip()
	print("DEBUG: Join selected room ", _get_room_number(), " port=", room_port, " ip=", server_ip)
	var error = Network.join_game(nick_input.text.strip_edges(), skin_input.text.strip_edges().to_lower(), room_port, server_ip)
	if error != OK:
		join_in_progress = false
		print("DEBUG: Join failed immediately with error: ", error)
		return

func _on_connected_ok(_peer_id, _player_info):
	if not join_in_progress:
		return
	print("DEBUG: level _on_connected_ok waiting for local player spawn. local_peer=", multiplayer.get_unique_id())
	var player_spawned = await _wait_for_local_player_spawn()
	join_in_progress = false
	if not player_spawned:
		print("DEBUG: Connected to server but local player did not spawn in time.")
		menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	menu.hide()
	await get_tree().process_frame
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_connection_failed():
	join_in_progress = false
	menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_server_disconnected():
	join_in_progress = false
	menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _wait_for_local_player_spawn(max_frames: int = 120) -> bool:
	var local_peer_id = multiplayer.get_unique_id()
	if local_peer_id <= 0:
		return false
	for _frame in max_frames:
		await get_tree().process_frame
		if players_container.has_node(str(local_peer_id)):
			print("DEBUG: Local player node appeared for peer ", local_peer_id)
			return true
	return false
	
func get_spawn_point() -> Vector3:
	if is_instance_valid(chair):
		return chair.position + SPAWN_OFFSET
	return Vector3(1.5, 0.05, 12.58)
	
func _remove_player(id):
	if not multiplayer.is_server() or not players_container.has_node(str(id)):
		return
	var player_node = players_container.get_node(str(id))
	if player_node:
		player_node.queue_free()
		
@rpc("any_peer", "call_local")
func sync_player_position(id: int, new_position: Vector3):
	var player = players_container.get_node(str(id))
	if player:
		player.position = new_position
		
@rpc("any_peer", "call_local")
func sync_player_skin(id: int, skin_name: String):
	var player = players_container.get_node(str(id))
	if player:
		player.set_player_skin(skin_name)
		
func _on_quit_pressed() -> void:
	get_tree().quit()
	
# ---------- MULTIPLAYER CHAT ----------
func toggle_chat():
	if menu.visible:
		return

	chat_visible = !chat_visible
	if chat_visible:
		# multiplayer_chat.show()
		chat_title.show()
		chat.show()
		message.grab_focus()
	else:
		# multiplayer_chat.hide() # instead of hiding the entire chat, just hide the chat_title and chat
		chat_title.hide()
		chat.hide()
		get_viewport().set_input_as_handled()

func is_chat_visible() -> bool:
	return chat_visible

func _input(event):
	if event.is_action_pressed("audio_test"):
		_play_audio_test_tone()
		return
	if event.is_action_pressed("toggle_chat"):
		toggle_chat()
	elif event is InputEventKey and event.keycode == KEY_ENTER:
		if chat_visible and message.has_focus():
			_on_send_pressed()
	elif event.is_action_pressed("leave_mouse"):  # Escape key unlocks mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Prevent message input unless chat is visible, BUT allow input when in menu
	if not chat_visible and not menu.visible and event is InputEventKey:
		get_viewport().set_input_as_handled()  # Ignore input when chat is hidden & menu is closed

	# Click outside chat to refocus on game ONLY if menu is hidden
	if event is InputEventMouseButton and event.pressed and not menu.visible:
		var mouse_pos = event.position
		if chat_visible and not message.get_global_rect().has_point(mouse_pos) and not send.get_global_rect().has_point(mouse_pos) and not chat.get_global_rect().has_point(mouse_pos):
			toggle_chat()  # Hide chat when clicking outside
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock mouse back to game




func _on_send_pressed() -> void:
	var trimmed_message = message.text.strip_edges()
	if trimmed_message == "":
		return # do not send empty messages

	var nick = Network.players[multiplayer.get_unique_id()]["nick"]
	
	rpc("msg_rpc", nick, trimmed_message)
	message.text = ""
	message.grab_focus()

@rpc("any_peer", "call_local")
func msg_rpc(nick, msg):
	chat.text += str(nick, " : ", msg, "\n")
	var sender_id = multiplayer.get_remote_sender_id()
	var player = players_container.get_node(str(sender_id))
	print("Message from ", nick, " : ", msg)
	if player:
		player.rpc("display_chat_message", msg)
