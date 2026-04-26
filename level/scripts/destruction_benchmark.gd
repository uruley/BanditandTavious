extends Node3D

const DEFAULT_PROJECTILE_SCENE := preload("res://simple_projectile.tscn")

@export var benchmark_label := "destruction-benchmark"
@export var target_scene: PackedScene
@export var projectile_scene: PackedScene = DEFAULT_PROJECTILE_SCENE
@export var launch_delay := 0.75
@export var sample_times := PackedFloat32Array([0.3, 1.0])
@export var post_sample_quit_delay := 2.0
@export var projectile_damage := 1.0
@export var projectile_speed := 18.0
@export var projectile_radius := 0.05

@onready var projectile_spawn: Marker3D = $ProjectileSpawn
@onready var target_anchor: Marker3D = $TargetAnchor

var _target_instance: Node3D
var _target_origin := Vector3.ZERO
var _start_msec := 0
var _impact_detected := false
var _impact_msec := 0
var _pre_impact_deltas: Array[float] = []
var _post_impact_deltas: Array[float] = []

func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	if target_scene == null:
		push_error("DestructionBenchmark: target_scene is not assigned")
		get_tree().quit(1)
		return

	_spawn_target()
	print("%s: ready" % benchmark_label)
	await get_tree().create_timer(launch_delay).timeout
	_spawn_projectile()

	var sorted_samples: Array = Array(sample_times)
	sorted_samples.sort()
	var last_sample_time := 0.0
	for sample_time_variant in sorted_samples:
		var sample_time := float(sample_time_variant)
		var wait_time: float = max(sample_time - last_sample_time, 0.0)
		if wait_time > 0.0:
			await get_tree().create_timer(wait_time).timeout
		last_sample_time = sample_time
		_capture_metrics(_format_sample_label(sample_time))

	if post_sample_quit_delay > 0.0:
		await get_tree().create_timer(post_sample_quit_delay).timeout
	print("%s: exiting" % benchmark_label)
	get_tree().quit()

func _process(delta: float) -> void:
	if _impact_detected:
		_post_impact_deltas.append(delta)
	else:
		_pre_impact_deltas.append(delta)

func _spawn_target() -> void:
	_target_instance = target_scene.instantiate() as Node3D
	if _target_instance == null:
		push_error("DestructionBenchmark: target_scene did not instantiate as Node3D")
		get_tree().quit(1)
		return
	add_child(_target_instance)
	_target_instance.global_transform = target_anchor.global_transform
	_target_origin = _target_instance.global_position

func _spawn_projectile() -> void:
	if _target_instance == null or not is_instance_valid(_target_instance):
		push_error("DestructionBenchmark: target instance missing before projectile launch")
		get_tree().quit(1)
		return
	var projectile: Area3D = projectile_scene.instantiate() as Area3D
	if projectile == null:
		push_error("DestructionBenchmark: projectile_scene did not instantiate as Area3D")
		get_tree().quit(1)
		return
	add_child(projectile)
	projectile.global_position = projectile_spawn.global_position
	projectile.direction = (_target_instance.global_position - projectile_spawn.global_position).normalized()
	projectile.damage = projectile_damage
	projectile.speed = projectile_speed
	projectile.radius = projectile_radius
	projectile.shooter = self
	print("%s: projectile launched" % benchmark_label)

func _capture_metrics(label: String) -> void:
	if not _impact_detected and (_target_instance == null or not is_instance_valid(_target_instance)):
		_impact_detected = true
		_impact_msec = Time.get_ticks_msec()

	var shard_bodies: Array = get_tree().get_nodes_in_group("shards")
	var shard_count := 0
	var max_distance := 0.0
	var avg_height := 0.0
	var spread_sum := 0.0

	for node in shard_bodies:
		if node is RigidBody3D:
			shard_count += 1
			var shard_pos: Vector3 = node.global_position
			var spread_distance := shard_pos.distance_to(_target_origin)
			max_distance = max(max_distance, spread_distance)
			spread_sum += spread_distance
			avg_height += shard_pos.y

	if shard_count > 0:
		avg_height /= shard_count

	var summary: Dictionary = {
		"benchmark_label": benchmark_label,
		"label": label,
		"elapsed_msec": Time.get_ticks_msec() - _start_msec,
		"impact_detected": _impact_detected,
		"impact_elapsed_msec": _impact_msec - _start_msec if _impact_msec > 0 else -1,
		"target_present": _target_instance != null and is_instance_valid(_target_instance),
		"target_origin": {"x": _target_origin.x, "y": _target_origin.y, "z": _target_origin.z},
		"shard_count": shard_count,
		"max_shard_distance_from_target_origin": max_distance,
		"average_shard_distance_from_target_origin": spread_sum / shard_count if shard_count > 0 else 0.0,
		"average_shard_height": avg_height,
		"pre_impact_avg_delta": _average_delta(_pre_impact_deltas),
		"post_impact_avg_delta": _average_delta(_post_impact_deltas),
		"pre_impact_sample_count": _pre_impact_deltas.size(),
		"post_impact_sample_count": _post_impact_deltas.size()
	}
	print("DESTRUCTION_METRICS %s" % JSON.stringify(summary))

func _average_delta(samples: Array[float]) -> float:
	if samples.is_empty():
		return -1.0
	var total := 0.0
	for sample in samples:
		total += sample
	return total / samples.size()

func _format_sample_label(sample_time: float) -> String:
	var rounded := snappedf(sample_time, 0.1)
	return "t_plus_%ss" % str(rounded).replace(".", "_")
