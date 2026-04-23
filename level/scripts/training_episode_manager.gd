extends Node3D

@export var episode_duration: float = 60.0
@export var max_episodes: int = 500
@export var population_size: int = 3

@onready var evolution_engine: Node = $EvolutionEngine
@onready var pickup_container: Node3D = $Pickups

var episode_timer: float = 0.0
var episode_count: int = 0
var agents_by_role: Dictionary = {"enemy": [], "citizen": [], "companion": []}

const SPAWN_ZONES := {
	"enemy": [Vector3(-14.0, 1.0, -10.0), Vector3(-14.0, 1.0, 0.0), Vector3(-14.0, 1.0, 10.0)],
	"citizen": [Vector3(13.0, 1.0, -8.0), Vector3(13.0, 1.0, 4.0), Vector3(11.0, 1.0, 12.0)],
	"companion": [Vector3(9.0, 1.0, -10.0), Vector3(10.0, 1.0, 2.0), Vector3(9.0, 1.0, 10.0)],
}

const PICKUP_POSITIONS := [
	Vector3(-7.0, 0.5, -7.0), Vector3(0.0, 0.5, -9.0), Vector3(7.0, 0.5, -5.0),
	Vector3(-9.0, 0.5, 3.0), Vector3(0.0, 0.5, 7.0), Vector3(7.0, 0.5, 9.0),
	Vector3(-5.0, 0.5, 11.0), Vector3(5.0, 0.5, -11.0),
]

const ROLE_SCRIPTS := {
	"enemy": "res://level/scripts/training_enemy.gd",
	"citizen": "res://level/scripts/training_citizen.gd",
	"companion": "res://level/scripts/training_companion.gd",
}


func _ready() -> void:
	_apply_cli_overrides()
	_spawn_all_agents()
	_spawn_pickups()
	_start_episode()


func _process(delta: float) -> void:
	episode_timer -= delta
	if episode_timer <= 0.0:
		_end_episode()


func _start_episode() -> void:
	episode_count += 1
	episode_timer = episode_duration
	_reset_agents()
	_reset_pickups()
	print("[Episode] %d / %d  (%.0fs)" % [episode_count, max_episodes, episode_duration])


func _end_episode() -> void:
	_collect_fitness()
	evolution_engine.evolve()

	if episode_count >= max_episodes:
		print("[Training] Done — %d episodes complete." % episode_count)
		if DisplayServer.get_name() == "headless":
			get_tree().quit()
		return

	_start_episode()


func _collect_fitness() -> void:
	for role in agents_by_role:
		var agents: Array = agents_by_role[role]
		for i in agents.size():
			var agent = agents[i]
			if agent.has_method("get_fitness_score"):
				evolution_engine.record_score(role, i, agent.get_fitness_score())


func _spawn_all_agents() -> void:
	for role in ROLE_SCRIPTS:
		var script = load(ROLE_SCRIPTS[role])
		agents_by_role[role] = []

		for i in population_size:
			var agent := CharacterBody3D.new()
			agent.name = "%s_%d" % [role, i]

			var col := CollisionShape3D.new()
			col.name = "CollisionShape3D"
			agent.add_child(col)

			var mesh := MeshInstance3D.new()
			mesh.name = "BodyMesh"
			agent.add_child(mesh)

			agent.script = script
			add_child(agent)
			agents_by_role[role].append(agent)


func _reset_agents() -> void:
	for role in agents_by_role:
		var agents: Array = agents_by_role[role]
		var spawns: Array = SPAWN_ZONES[role]
		for i in agents.size():
			var params: Dictionary = evolution_engine.get_params(role, i)
			var pos: Vector3 = spawns[i % spawns.size()]
			if agents[i].has_method("reset_for_episode"):
				agents[i].reset_for_episode(params, pos)


func _spawn_pickups() -> void:
	var pickup_script = load("res://level/scripts/training_pickup.gd")
	for pos in PICKUP_POSITIONS:
		var pickup := Area3D.new()
		pickup.name = "Pickup"

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.6
		col.shape = shape
		pickup.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.7
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.3, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.0, 0.4, 0.1, 1.0)
		mesh_inst.material_override = mat
		pickup.add_child(mesh_inst)

		pickup.script = pickup_script
		pickup.position = pos
		pickup_container.add_child(pickup)


func _reset_pickups() -> void:
	for pickup in pickup_container.get_children():
		if pickup.has_method("reset"):
			pickup.reset()


func _apply_cli_overrides() -> void:
	var args := _parse_cli_args()
	if args.has("episodes"):
		max_episodes = max(1, int(args["episodes"]))
	if args.has("duration"):
		episode_duration = max(1.0, float(args["duration"]))
	if args.has("seed"):
		seed(int(args["seed"]))
	print("[Training] Config episodes=%d duration=%.2f population=%d headless=%s" % [
		max_episodes, episode_duration, population_size, str(DisplayServer.get_name() == "headless")
	])


func _parse_cli_args() -> Dictionary:
	var parsed := {}
	for raw_arg in OS.get_cmdline_user_args():
		var arg := String(raw_arg).strip_edges()
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var sep := body.find("=")
		if sep <= 0:
			continue
		var key := body.substr(0, sep).to_lower()
		var value := body.substr(sep + 1)
		parsed[key] = value
	return parsed
