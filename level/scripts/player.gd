extends CharacterBody3D

const NORMAL_SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 10
const FLIGHT_SPEED = 18.0
const FLIGHT_VERTICAL_SPEED = 12.0
const FLIGHT_INTERACT_DISTANCE = 4.0
const FLIGHT_PLATFORM_OFFSET = Vector3(0.0, -0.95, 0.2)
const VOICE_CAPTURE_BUS := "VoiceCapture"
const VOICE_CHUNK_FRAMES := 512
const VOICE_BUFFER_LENGTH := 0.4
const VOICE_MAX_DISTANCE := 35.0
const VOICE_UNIT_SIZE := 8.0

@onready var nickname: Label3D = $PlayerNick/Nickname
@onready var chat_label: Label3D = $PlayerChat/Text
@onready var muzzle: Node3D = $Muzzle

var bullet_scene = preload("res://level/scenes/bullet.tscn")

@export_category("Objects")
@export var _body: Node3D = null
@export var _spring_arm_offset: Node3D = null

@export_category("Skin Colors")
@export var blue_texture : CompressedTexture2D
@export var yellow_texture : CompressedTexture2D
@export var green_texture : CompressedTexture2D
@export var red_texture : CompressedTexture2D

var _current_speed: float
var _respawn_point = Vector3(0, 5, 0)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var _is_flying := false
var _flight_platform: MeshInstance3D = null
var _voice_capture: AudioEffectCapture = null
var _voice_microphone_player: AudioStreamPlayer = null
var _voice_playback_player: AudioStreamPlayer3D = null
var _voice_playback: AudioStreamGeneratorPlayback = null

func _enter_tree():
	$SpringArmOffset/SpringArm3D/Camera3D.current = false
	
func _ready():
	_create_flight_platform()
	_setup_voice_playback()
	if not await _configure_multiplayer_state():
		push_warning("Player spawned without a replicated peer id: %s" % name)
		return
	if is_multiplayer_authority():
		_setup_voice_capture()

func _configure_multiplayer_state() -> bool:
	var cam = $SpringArmOffset/SpringArm3D/Camera3D
	for _attempt in 4:
		await get_tree().process_frame
		var peer_id = str(name).to_int()
		var local_peer_id = multiplayer.get_unique_id()
		if peer_id <= 0 or local_peer_id <= 0:
			continue
		set_multiplayer_authority(peer_id)
		var is_local_player = peer_id == local_peer_id
		cam.current = is_local_player
		if is_local_player:
			cam.make_current() # Force it once the replicated peer id is stable.
			print("DEBUG: Camera FORCED current for local player: ", name)
		return true
	cam.current = false
	return false
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	var current_scene = get_tree().get_current_scene()
	if current_scene and current_scene.has_method("is_chat_visible") and current_scene.is_chat_visible() and is_on_floor():
		freeze()
		return

	if Input.is_action_just_pressed("interact"):
		_toggle_flight_mount()

	if _is_flying:
		_fly_move()
		move_and_slide()
		_body.animate(velocity)
		return
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
		_body.animate(velocity)
	
	_move()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		
	move_and_slide()
	_body.animate(velocity)
	_check_fall_and_respawn()

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if not Input.is_action_pressed("voice_chat"):
		return
	if _voice_capture == null:
		return
	while _voice_capture.can_get_buffer(VOICE_CHUNK_FRAMES):
		var voice_frames: PackedVector2Array = _voice_capture.get_buffer(VOICE_CHUNK_FRAMES)
		if voice_frames.is_empty():
			break
		_receive_voice_chunk.rpc(voice_frames)
	
func freeze():
	velocity.x = 0
	velocity.z = 0
	velocity.y = 0
	_current_speed = 0
	_body.animate(Vector3.ZERO)
	
func _move() -> void:
	var _input_direction: Vector2 = Vector2.ZERO
	if is_multiplayer_authority():
		_input_direction = Input.get_vector(
			"move_left", "move_right",
			"move_forward", "move_backward"
			)

	var _direction: Vector3 = transform.basis * Vector3(_input_direction.x, 0, _input_direction.y).normalized()
	
	is_running()
	_direction = _direction.rotated(Vector3.UP, _spring_arm_offset.rotation.y)
	
	if _direction:
		velocity.x = _direction.x * _current_speed
		velocity.z = _direction.z * _current_speed
		_body.apply_rotation(velocity)
		return
	
	velocity.x = move_toward(velocity.x, 0, _current_speed)
	velocity.z = move_toward(velocity.z, 0, _current_speed)

func _fly_move() -> void:
	var input_direction := Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_backward"
	)
	var basis := _spring_arm_offset.global_transform.basis
	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()
	var move_direction := (right * input_direction.x) + (forward * input_direction.y)
	if move_direction.length_squared() > 0.0:
		move_direction = move_direction.normalized()
		velocity.x = move_direction.x * FLIGHT_SPEED
		velocity.z = move_direction.z * FLIGHT_SPEED
		_body.apply_rotation(Vector3(velocity.x, 0.0, velocity.z))
	else:
		velocity.x = move_toward(velocity.x, 0.0, FLIGHT_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, FLIGHT_SPEED)

	var vertical := 0.0
	if Input.is_action_pressed("jump"):
		vertical += 1.0
	if Input.is_action_pressed("shift"):
		vertical -= 1.0
	velocity.y = vertical * FLIGHT_VERTICAL_SPEED
	
func is_running() -> bool:
	if Input.is_action_pressed("shift"):
		_current_speed = SPRINT_SPEED
		return true
	else:
		_current_speed = NORMAL_SPEED
		return false
		
func _check_fall_and_respawn():
	if global_transform.origin.y < -15.0:
		_respawn()
		
func _respawn():
	global_transform.origin = _respawn_point
	velocity = Vector3.ZERO

func _toggle_flight_mount() -> void:
	if _is_flying:
		_set_flight_mode(false)
		return

	var current_scene := get_tree().get_current_scene()
	if current_scene == null:
		return
	var flight_pad := current_scene.get_node_or_null("FlightPad")
	if flight_pad == null or global_position.distance_to(flight_pad.global_position) > FLIGHT_INTERACT_DISTANCE:
		return
	var mount_point := flight_pad.get_node_or_null("MountPoint")
	var mount_position: Vector3 = flight_pad.global_position + Vector3(0.0, 1.05, 0.0)
	if mount_point:
		mount_position = mount_point.global_position
	global_position = mount_position
	_respawn_point = mount_position
	_set_flight_mode(true)

func _set_flight_mode(enabled: bool) -> void:
	_is_flying = enabled
	velocity = Vector3.ZERO
	if _flight_platform:
		_flight_platform.visible = enabled

func _create_flight_platform() -> void:
	if _flight_platform != null:
		return
	_flight_platform = MeshInstance3D.new()
	_flight_platform.name = "FlightPlatform"
	var platform_mesh := BoxMesh.new()
	platform_mesh.size = Vector3(2.6, 0.18, 4.2)
	_flight_platform.mesh = platform_mesh
	var platform_material := StandardMaterial3D.new()
	platform_material.albedo_color = Color(0.85, 0.86, 0.92, 1.0)
	platform_material.metallic = 0.35
	platform_material.roughness = 0.25
	platform_material.emission_enabled = true
	platform_material.emission = Color(0.12, 0.16, 0.24, 1.0)
	_flight_platform.material_override = platform_material
	_flight_platform.position = FLIGHT_PLATFORM_OFFSET
	_flight_platform.visible = false
	add_child(_flight_platform)

func _setup_voice_capture() -> void:
	_ensure_voice_capture_bus()
	var bus_index := AudioServer.get_bus_index(VOICE_CAPTURE_BUS)
	if bus_index == -1:
		return
	var effect := AudioServer.get_bus_effect(bus_index, 0)
	if effect is AudioEffectCapture:
		_voice_capture = effect
		_voice_capture.clear_buffer()
	if _voice_microphone_player == null:
		_voice_microphone_player = AudioStreamPlayer.new()
		_voice_microphone_player.name = "VoiceMicrophone"
		_voice_microphone_player.bus = VOICE_CAPTURE_BUS
		_voice_microphone_player.stream = AudioStreamMicrophone.new()
		add_child(_voice_microphone_player)
	if not _voice_microphone_player.playing:
		_voice_microphone_player.play()

func _setup_voice_playback() -> void:
	if _voice_playback_player != null:
		return
	_voice_playback_player = AudioStreamPlayer3D.new()
	_voice_playback_player.name = "VoicePlayback"
	var voice_stream := AudioStreamGenerator.new()
	voice_stream.buffer_length = VOICE_BUFFER_LENGTH
	voice_stream.mix_rate = AudioServer.get_mix_rate()
	_voice_playback_player.stream = voice_stream
	_voice_playback_player.max_distance = VOICE_MAX_DISTANCE
	_voice_playback_player.unit_size = VOICE_UNIT_SIZE
	_voice_playback_player.position = Vector3(0.0, 1.6, 0.0)
	add_child(_voice_playback_player)
	_voice_playback_player.play()
	_refresh_voice_playback()

func _refresh_voice_playback() -> void:
	if _voice_playback_player == null:
		return
	_voice_playback = _voice_playback_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _ensure_voice_capture_bus() -> void:
	var bus_index := AudioServer.get_bus_index(VOICE_CAPTURE_BUS)
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, VOICE_CAPTURE_BUS)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
		var capture_effect := AudioEffectCapture.new()
		capture_effect.buffer_length = 0.3
		AudioServer.add_bus_effect(bus_index, capture_effect)
	elif AudioServer.get_bus_effect_count(bus_index) == 0:
		var capture_effect := AudioEffectCapture.new()
		capture_effect.buffer_length = 0.3
		AudioServer.add_bus_effect(bus_index, capture_effect)

@rpc("authority", "unreliable")
func _receive_voice_chunk(voice_frames: PackedVector2Array) -> void:
	if is_multiplayer_authority():
		return
	if _voice_playback == null:
		_refresh_voice_playback()
	if _voice_playback == null:
		return
	if not _voice_playback.can_push_buffer(voice_frames.size()):
		_voice_playback.clear_buffer()
	_voice_playback.push_buffer(voice_frames)
	
@rpc("any_peer", "reliable")
func change_nick(new_nick: String):
	if nickname:
		nickname.text = new_nick
		
func get_texture_from_name(skin_name: String) -> CompressedTexture2D:
	match skin_name:
		"blue": return blue_texture
		"green": return green_texture
		"red": return red_texture
		"yellow": return yellow_texture
		_: return blue_texture
		
@rpc("any_peer", "reliable")
func set_player_skin(skin_name: String) -> void:
	var texture = get_texture_from_name(skin_name)
	var bottom: MeshInstance3D = get_node("3DGodotRobot/RobotArmature/Skeleton3D/Bottom")
	var chest: MeshInstance3D = get_node("3DGodotRobot/RobotArmature/Skeleton3D/Chest")
	var face: MeshInstance3D = get_node("3DGodotRobot/RobotArmature/Skeleton3D/Face")
	var limbs_head: MeshInstance3D = get_node("3DGodotRobot/RobotArmature/Skeleton3D/Llimbs and head")
	
	set_mesh_texture(bottom, texture)
	set_mesh_texture(chest, texture)
	set_mesh_texture(face, texture)
	set_mesh_texture(limbs_head, texture)
	
func set_mesh_texture(mesh_instance: MeshInstance3D, texture: CompressedTexture2D) -> void:
	if mesh_instance:
		var material := mesh_instance.get_surface_override_material(0)
		if material and material is StandardMaterial3D:
			var new_material := material
			new_material.albedo_texture = texture
			mesh_instance.set_surface_override_material(0, new_material)

@rpc("any_peer", "reliable")
func display_chat_message(message: String):
	chat_label.text = message
	chat_label.show()  # Ensure the label is visible
	await get_tree().create_timer(10.0).timeout  # Correctly wait for the timeout signal
	chat_label.hide()  # Hide the message after 5 seconds

func shoot():
	var bullet_pos = muzzle.global_position
	var bullet_dir = -global_transform.basis.z # Shoot forward
	# If we want to shoot where camera is looking:
	if _spring_arm_offset:
		bullet_dir = -_spring_arm_offset.global_transform.basis.z
	
	spawn_bullet.rpc(bullet_pos, bullet_dir)

@rpc("any_peer", "call_local")
func spawn_bullet(pos: Vector3, dir: Vector3):
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = pos
	bullet.velocity = dir.normalized() * bullet.speed
	bullet.shooter_id = name.to_int()

func take_damage(_amount: int, _from_id: int):
	# Simple respawn on hit
	global_position = _respawn_point
	velocity = Vector3.ZERO
