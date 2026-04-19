@tool
extends Node
class_name MCPWSServer
## WebSocket SERVER for communication with external MCP clients.
## Listens on port 6550 for incoming connections from a Python MCP server.
## Uses JSON-RPC 2.0 protocol over WebSocket.

signal connected
signal disconnected
signal tool_requested(request_id: String, tool_name: String, args: Dictionary)

const DEFAULT_PORT := 6550
const MAX_PACKETS_PER_FRAME := 32
const HEARTBEAT_INTERVAL := 10.0

var _tcp_server: TCPServer = TCPServer.new()
var _peer: WebSocketPeer = null
var _pending_tcp: StreamPeerTCP = null
var _port: int = DEFAULT_PORT
var _is_connected := false
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

	_initialized = true

func start_server(port: int = DEFAULT_PORT) -> void:
	_port = port
	var err := _tcp_server.listen(_port)
	if err != OK:
		push_error("[MCP WS] Failed to listen on port %d: %s" % [_port, err])
		return
	print("[MCP WS] Listening on port ", _port)

func stop_server() -> void:
	_heartbeat_timer.stop()
	if _peer:
		_peer.close()
		_peer = null
	if _pending_tcp:
		_pending_tcp = null
	_tcp_server.stop()
	if _is_connected:
		_is_connected = false
		disconnected.emit()
	print("[MCP WS] Server stopped")

func _process(_delta: float) -> void:
	if not _initialized:
		return
	if not _tcp_server.is_listening():
		return

	# Accept new TCP connections
	if _tcp_server.is_connection_available():
		var tcp_peer := _tcp_server.take_connection()
		if _peer != null and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			# Already have a connected client, reject the new one
			print("[MCP WS] Rejecting connection - client already connected")
			tcp_peer.disconnect_from_host()
		else:
			# Accept new connection via WebSocket handshake
			_pending_tcp = tcp_peer
			_peer = WebSocketPeer.new()
			var err := _peer.accept_stream(_pending_tcp)
			if err != OK:
				push_error("[MCP WS] Failed to accept WebSocket: ", err)
				_peer = null
				_pending_tcp = null

	# Process active WebSocket peer
	if _peer:
		_peer.poll()
		var state := _peer.get_ready_state()

		match state:
			WebSocketPeer.STATE_OPEN:
				if not _is_connected:
					_handle_connect()
				var packets_processed := 0
				while _peer.get_available_packet_count() > 0 and packets_processed < MAX_PACKETS_PER_FRAME:
					var raw := _peer.get_packet().get_string_from_utf8()
					_handle_message(raw)
					packets_processed += 1

			WebSocketPeer.STATE_CLOSING:
				pass  # Wait for close

			WebSocketPeer.STATE_CLOSED:
				if _is_connected:
					_handle_disconnect()
				_peer = null
				_pending_tcp = null

func _handle_connect() -> void:
	_is_connected = true
	_heartbeat_timer.start()
	print("[MCP WS] Client connected")

	# Send godot_ready notification
	_send_notification("godot_ready", {"project_path": _project_path})
	connected.emit()

func _handle_disconnect() -> void:
	_is_connected = false
	_heartbeat_timer.stop()
	print("[MCP WS] Client disconnected")
	disconnected.emit()

func _handle_message(json_string: String) -> void:
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
			print("[MCP WS] Tool request: ", tool_name, " (", msg_id, ")")
			tool_requested.emit(str(msg_id), tool_name, args)
		"ping":
			_send_notification("pong")
		_:
			if method:
				print("[MCP WS] Unknown method: ", method)

func send_tool_result(request_id: String, success: bool, result = null, error: String = "") -> void:
	"""Send a JSON-RPC 2.0 response for a tool invocation."""
	var response: Dictionary = {
		"jsonrpc": "2.0",
		"id": request_id,
	}
	if success:
		response["result"] = result if result != null else {}
	else:
		response["error"] = {"code": -1, "message": error}

	_send_raw(response)
	print("[MCP WS] Sent result for ", request_id, " (success=", success, ")")

func push_event(event_type: String, data = null) -> void:
	"""Push an unsolicited event notification to the connected MCP client."""
	if not _is_connected:
		return
	_send_notification("event", {
		"type": event_type,
		"data": data,
		"timestamp": Time.get_unix_time_from_system(),
	})

func _send_notification(method: String, params: Dictionary = {}) -> void:
	"""Send a JSON-RPC 2.0 notification (no id)."""
	var msg: Dictionary = {"jsonrpc": "2.0", "method": method}
	if not params.is_empty():
		msg["params"] = params
	_send_raw(msg)

func _send_raw(message: Dictionary) -> void:
	if _peer and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_peer.send_text(JSON.stringify(message))

func _on_heartbeat() -> void:
	if _is_connected:
		_send_notification("ping")

func is_client_connected() -> bool:
	return _is_connected
