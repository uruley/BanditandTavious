@tool
extends Node
class_name MCPWSServer
## WebSocket SERVER for communication with external MCP clients.
## Listens on port 6550 for incoming connections from a Python MCP server.
## Supports multiple simultaneous clients (Claude Code, Codex, Gemini, etc.)
## Uses JSON-RPC 2.0 protocol over WebSocket.

signal connected
signal disconnected
signal tool_requested(request_id: String, tool_name: String, args: Dictionary)

const DEFAULT_PORT := 6550
const MAX_PACKETS_PER_FRAME := 32
const HEARTBEAT_INTERVAL := 10.0

var _tcp_server: TCPServer = TCPServer.new()
var _peers: Array = []           # Array of {ws: WebSocketPeer, tcp: StreamPeerTCP, ready: bool}
var _request_peer: Dictionary = {}  # request_id -> peer dict (so response goes to right client)
var _port: int = DEFAULT_PORT
var _heartbeat_timer: Timer
var _project_path: String
var _initialized := false

func _ready() -> void:
	_project_path = ProjectSettings.globalize_path("res://")

	_heartbeat_timer = Timer.new()
	_heartbeat_timer.one_shot = false
	_heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	_heartbeat_timer.timeout.connect(_on_heartbeat)
	add_child(_heartbeat_timer)
	_heartbeat_timer.start()

	_initialized = true

func start_server(port: int = DEFAULT_PORT) -> void:
	_port = port
	var err := _tcp_server.listen(_port)
	if err != OK:
		push_error("[MCP WS] Failed to listen on port %d: %s" % [_port, err])
		return
	print("[MCP WS] Listening on port ", _port, " (multi-client)")

func stop_server() -> void:
	_heartbeat_timer.stop()
	for entry in _peers:
		entry.ws.close()
	_peers.clear()
	_request_peer.clear()
	_tcp_server.stop()
	print("[MCP WS] Server stopped")

func is_client_connected() -> bool:
	for entry in _peers:
		if entry.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			return true
	return false

func _process(_delta: float) -> void:
	if not _initialized or not _tcp_server.is_listening():
		return

	# Accept all pending TCP connections
	while _tcp_server.is_connection_available():
		var tcp_peer := _tcp_server.take_connection()
		var ws := WebSocketPeer.new()
		var err := ws.accept_stream(tcp_peer)
		if err != OK:
			push_error("[MCP WS] Failed to accept WebSocket: ", err)
		else:
			_peers.append({ws = ws, tcp = tcp_peer, ready = false})
			print("[MCP WS] New client connecting (total: ", _peers.size(), ")")

	# Process all peers
	var i := 0
	while i < _peers.size():
		var entry: Dictionary = _peers[i]
		var ws: WebSocketPeer = entry.ws
		ws.poll()

		match ws.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				if not entry.ready:
					entry.ready = true
					print("[MCP WS] Client connected (total ready: ", _count_ready(), ")")
					_send_to(ws, _make_notification("godot_ready", {"project_path": _project_path}))
					if _count_ready() == 1:
						connected.emit()

				var packets := 0
				while ws.get_available_packet_count() > 0 and packets < MAX_PACKETS_PER_FRAME:
					_handle_message(ws.get_packet().get_string_from_utf8(), ws)
					packets += 1
				i += 1

			WebSocketPeer.STATE_CONNECTING:
				i += 1

			WebSocketPeer.STATE_CLOSING:
				i += 1

			WebSocketPeer.STATE_CLOSED:
				if entry.ready:
					print("[MCP WS] Client disconnected (remaining: ", _peers.size() - 1, ")")
				# Clean up any pending requests for this peer
				var to_remove: Array = []
				for req_id in _request_peer:
					if _request_peer[req_id] == ws:
						to_remove.append(req_id)
				for req_id in to_remove:
					_request_peer.erase(req_id)
				_peers.remove_at(i)
				if _count_ready() == 0:
					disconnected.emit()

func _count_ready() -> int:
	var count := 0
	for entry in _peers:
		if entry.ready:
			count += 1
	return count

func _handle_message(json_string: String, ws: WebSocketPeer) -> void:
	var message = JSON.parse_string(json_string)
	if message == null:
		push_error("[MCP WS] Failed to parse JSON: ", json_string.left(200))
		return

	var method: String = message.get("method", "")
	var msg_id = message.get("id", "")

	match method:
		"tool_invoke":
			var params: Dictionary = message.get("params", {})
			var tool_name: String = params.get("tool", "")
			var args: Dictionary = params.get("args", {})
			var req_id := str(msg_id)
			_request_peer[req_id] = ws
			print("[MCP WS] Tool request: ", tool_name, " (", req_id, ")")
			tool_requested.emit(req_id, tool_name, args)
		"ping":
			_send_to(ws, _make_notification("pong"))
		_:
			if method:
				print("[MCP WS] Unknown method: ", method)

func send_tool_result(request_id: String, success: bool, result = null, error: String = "") -> void:
	var ws: WebSocketPeer = _request_peer.get(request_id)
	_request_peer.erase(request_id)

	var response: Dictionary = {"jsonrpc": "2.0", "id": request_id}
	if success:
		response["result"] = result if result != null else {}
	else:
		response["error"] = {"code": -1, "message": error}

	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_send_to(ws, response)
		print("[MCP WS] Sent result for ", request_id, " (success=", success, ")")
	else:
		print("[MCP WS] Client gone before result for ", request_id, " could be sent")

func push_event(event_type: String, data = null) -> void:
	var msg := _make_notification("event", {
		"type": event_type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system(),
	})
	for entry in _peers:
		if entry.ready and entry.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_send_to(entry.ws, msg)

func _make_notification(method: String, params: Dictionary = {}) -> Dictionary:
	var msg: Dictionary = {"jsonrpc": "2.0", "method": method}
	if not params.is_empty():
		msg["params"] = params
	return msg

func _send_to(ws: WebSocketPeer, message: Dictionary) -> void:
	if ws and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(message))

func _on_heartbeat() -> void:
	var ping := _make_notification("ping")
	for entry in _peers:
		if entry.ready and entry.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_send_to(entry.ws, ping)
