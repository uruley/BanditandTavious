extends Node3D

@export var episode_duration: float = 60.0
@export var result_path: String = "user://episode_result.json"

const NUM_PICKUPS := 8
const MIN_PICKUP_DIST := 3.5   # min distance between pickups
const SPAWN_CLEAR_DIST := 3.0  # min distance from agent spawn (0,0)

# Fixed obstacle pillars — block straight-line paths
const PILLAR_POSITIONS := [
	Vector3(-4.0, 0.75, -4.0),
	Vector3( 4.0, 0.75, -4.0),
	Vector3(-4.0, 0.75,  4.0),
	Vector3( 4.0, 0.75,  4.0),
	Vector3( 0.0, 0.75, -7.0),
	Vector3( 0.0, 0.75,  7.0),
]

var timer: float = 0.0
var total_pickups: int = 0
var done: bool = false
var pickup_positions: Array = []


func _ready() -> void:
	timer = episode_duration
	_generate_pickup_positions()
	_spawn_pillars()
	_spawn_agent()
	_spawn_pickups()
	await get_tree().process_frame
	total_pickups = get_tree().get_nodes_in_group("pickup").size()
	print("[Arena] Episode start — %d pickups, %.0fs, %d pillars" % [total_pickups, episode_duration, PILLAR_POSITIONS.size()])


func _process(delta: float) -> void:
	if done:
		return
	timer -= delta
	var remaining := 0
	for p in get_tree().get_nodes_in_group("pickup"):
		if p.visible:
			remaining += 1
	if remaining == 0 or timer <= 0.0:
		_end_episode()


func _generate_pickup_positions() -> void:
	pickup_positions.clear()
	var attempts := 0
	while pickup_positions.size() < NUM_PICKUPS and attempts < 500:
		attempts += 1
		var x := randf_range(-8.5, 8.5)
		var z := randf_range(-8.5, 8.5)
		var pos := Vector3(x, 0.5, z)
		# Too close to agent spawn
		if Vector2(x, z).length() < SPAWN_CLEAR_DIST:
			continue
		# Too close to another pickup
		var too_close := false
		for existing in pickup_positions:
			if pos.distance_to(existing) < MIN_PICKUP_DIST:
				too_close = true
				break
		if not too_close:
			pickup_positions.append(pos)


func _spawn_pillars() -> void:
	for pos in PILLAR_POSITIONS:
		var pillar := CSGBox3D.new()
		pillar.size = Vector3(1.5, 1.5, 1.5)
		pillar.position = pos
		pillar.use_collision = true
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2)
		pillar.material = mat
		add_child(pillar)


func _spawn_agent() -> void:
	var agent := CharacterBody3D.new()
	agent.name = "Agent"

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.height = 1.8
	cap.radius = 0.4
	col.shape = cap
	col.position = Vector3(0.0, 0.9, 0.0)
	agent.add_child(col)

	var mesh := MeshInstance3D.new()
	mesh.name = "BodyMesh"
	var m := CapsuleMesh.new()
	m.height = 1.8
	m.radius = 0.4
	mesh.mesh = m
	mesh.position = Vector3(0.0, 0.9, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.9)
	mesh.material_override = mat
	agent.add_child(mesh)

	agent.script = load("res://level/scripts/karpathy_agent.gd")
	agent.position = Vector3(0.0, 1.0, 0.0)
	add_child(agent)


func _spawn_pickups() -> void:
	var pickup_script = load("res://level/scripts/karpathy_pickup.gd")
	for pos in pickup_positions:
		var pickup := Area3D.new()
		pickup.script = pickup_script

		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape := SphereShape3D.new()
		shape.radius = 0.55
		col.shape = shape
		pickup.add_child(col)

		var mesh := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		mesh.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.5, 0.1)
		mesh.material_override = mat
		pickup.add_child(mesh)

		pickup.position = pos
		add_child(pickup)


func _end_episode() -> void:
	done = true
	var collected := 0
	for p in get_tree().get_nodes_in_group("pickup"):
		if not p.visible:
			collected += 1

	var time_used: float = episode_duration - timer
	var composite: float = collected * 100.0 + maxf(timer, 0.0)

	var result := {
		"pickups_collected": collected,
		"total_pickups": total_pickups,
		"time_used": time_used,
		"time_remaining": maxf(timer, 0.0),
		"episode_duration": episode_duration,
		"score": composite,
	}

	var file := FileAccess.open(result_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result))
		file.close()

	print("[Arena] Done — %d / %d pickups in %.1fs (score %.1f)" % [collected, total_pickups, time_used, composite])
	get_tree().quit()
