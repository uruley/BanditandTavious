extends Node3D

@onready var skin_input: LineEdit = $Menu/MainContainer/MainMenu/Option2/SkinInput
@onready var nick_input: LineEdit = $Menu/MainContainer/MainMenu/Option1/NickInput
@onready var room_input: LineEdit = $Menu/MainContainer/MainMenu/Option5/RoomInput
@onready var ip_input: LineEdit = $Menu/MainContainer/MainMenu/Option6/IPInput
@onready var players_container: Node3D = $PlayersContainer
@onready var menu: Control = $Menu
@export var player_scene: PackedScene

# multiplayer chat
@onready var message: LineEdit = $MultiplayerChat/Message
@onready var send: Button = $MultiplayerChat/Send
@onready var chat: TextEdit = $MultiplayerChat/Chat
@onready var chat_title: Label = $MultiplayerChat/ChatTitle
@onready var multiplayer_chat: Control = $MultiplayerChat
var chat_visible = false
var join_in_progress = false

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
	var spawn_pos = Vector2.from_angle(randf() * 2 * PI) * 10 # spawn radius
	return Vector3(spawn_pos.x, 5.0, spawn_pos.y)
	
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
