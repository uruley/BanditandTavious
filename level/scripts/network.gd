extends Node

const SERVER_ADDRESS: String = "127.0.0.1"
const DEFAULT_PORT: int = 8080
const MAX_PLAYERS : int = 10

var players = {}
var player_info = {
	"nick" : "host",
	"skin" : "blue"
}

signal player_connected(peer_id, player_info)
signal connected_ok(peer_id, player_info)
signal connection_failed
signal server_disconnected

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit(0)
		
func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.connected_to_server.connect(_on_connected_ok)

func start_host(port: int = DEFAULT_PORT):
	print("DEBUG: start_host on peer ", multiplayer.get_unique_id(), " port=", port)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	if error:
		print("DEBUG: start_host failed with error: ", error)
		return error
	multiplayer.multiplayer_peer = peer
	
	var host_info = player_info.duplicate(true)
	players[1] = host_info
	player_connected.emit(1, host_info)
	return OK
	
func join_game(nickname: String, skin_color: String, port: int = DEFAULT_PORT, ip_address: String = SERVER_ADDRESS):
	print("DEBUG: join_game requested ip=", ip_address, " port=", port, " nick=", nickname, " skin=", skin_color)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, port)
	if error:
		print("DEBUG: join_game failed with error: ", error)
		return error

	multiplayer.multiplayer_peer = peer
	if !nickname:
		nickname = "Player_" + str(multiplayer.get_unique_id())
	if !skin_color or (skin_color != "red" and skin_color != "blue" and skin_color != "green" and skin_color != "yellow"):
		skin_color = "blue"
	player_info["nick"] = nickname
	player_info["skin"] = skin_color
	return OK
	
func _on_connected_ok():
	print("DEBUG: _on_connected_ok - Local Peer ID: ", multiplayer.get_unique_id())
	var peer_id = multiplayer.get_unique_id()
	var local_info = player_info.duplicate(true)
	players[peer_id] = local_info
	player_connected.emit(peer_id, local_info)
	connected_ok.emit(peer_id, local_info)
	
func _on_player_connected(id):
	print("DEBUG: network peer_connected on local peer ", multiplayer.get_unique_id(), " for remote peer ", id, " info=", player_info)
	_register_player.rpc_id(id, player_info.duplicate(true))
	
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	print("DEBUG: _register_player on local peer ", multiplayer.get_unique_id(), " from remote peer ", new_player_id, " info=", new_player_info)
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	#print("debug function _register_player on Network.gd: ", players, "\n")
	
func _on_player_disconnected(id):
	print("DEBUG: peer_disconnected on local peer ", multiplayer.get_unique_id(), " for remote peer ", id)
	players.erase(id)
	
func _on_connection_failed():
	print("DEBUG: connection_failed on local peer ", multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = null
	players.clear()
	connection_failed.emit()

func _on_server_disconnected():
	print("DEBUG: server_disconnected on local peer ", multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
