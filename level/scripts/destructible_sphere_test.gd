extends Node3D

const PROJECTILE_SCENE := preload("res://simple_projectile.tscn")

@onready var projectile_spawn: Marker3D = $ProjectileSpawn
@onready var destructible_sphere: RigidBody3D = $DestructibleSphere

var _start_msec: int = 0
var _impact_detected := false
var _impact_msec: int = 0
var _pre_impact_deltas: Array[float] = []
var _post_impact_deltas: Array[float] = []

func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	print("DestructibleSphereTest: ready")
	await get_tree().create_timer(0.75).timeout
	_spawn_projectile()
	await get_tree().create_timer(0.3).timeout
	_capture_metrics("t_plus_0_3s")
	await get_tree().create_timer(0.7).timeout
	_capture_metrics("t_plus_1_0s")
	await get_tree().create_timer(2.0).timeout
	print("DestructibleSphereTest: exiting")
	get_tree().quit()

func _process(delta: float) -> void:
	if _impact_detected:
		_post_impact_deltas.append(delta)
	else:
		_pre_impact_deltas.append(delta)

func _spawn_projectile() -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	add_child(projectile)
	projectile.global_position = projectile_spawn.global_position
	projectile.direction = (destructible_sphere.global_position - projectile_spawn.global_position).normalized()
	projectile.damage = 1.0
	projectile.speed = 18.0
	projectile.shooter = self
	print("DestructibleSphereTest: projectile launched")

func _capture_metrics(label: String) -> void:
	if not _impact_detected:
		_impact_detected = not is_instance_valid(destructible_sphere)
		if _impact_detected:
			_impact_msec = Time.get_ticks_msec()

	var shard_root := get_node_or_null("fractured_sphere")
	var shard_count := 0
	var max_distance := 0.0
	var avg_height := 0.0
	var center := Vector3.ZERO

	if shard_root:
		var total_height := 0.0
		for child in shard_root.get_children():
			if child is RigidBody3D:
				shard_count += 1
				var shard_pos: Vector3 = child.global_position
				max_distance = max(max_distance, shard_pos.length())
				total_height += shard_pos.y
		if shard_count > 0:
			avg_height = total_height / shard_count
		center = shard_root.global_position

	var summary := {
		"label": label,
		"elapsed_msec": Time.get_ticks_msec() - _start_msec,
		"impact_detected": _impact_detected,
		"impact_elapsed_msec": _impact_msec - _start_msec if _impact_msec > 0 else -1,
		"shard_root_present": shard_root != null,
		"shard_count": shard_count,
		"max_shard_distance_from_origin": max_distance,
		"average_shard_height": avg_height,
		"shard_root_center": {"x": center.x, "y": center.y, "z": center.z},
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
