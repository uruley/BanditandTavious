extends Node

var reservations: Dictionary = {}


func _ready() -> void:
	add_to_group("lyra_ai_task_board")


func find_and_reserve(goal: String, actor: Node3D, selection_mode: String = "nearest", excluded_names: Array[String] = []) -> Node3D:
	var actor_id := actor.name
	var best_target: Node3D
	var best_distance := -INF if selection_mode == "farthest" else INF
	var needs_reservation := goal != "combat" and goal != "explore" and goal != "build"

	for candidate_variant in _candidate_nodes_for_goal(goal):
		var candidate := candidate_variant as Node3D
		if candidate == null or not _is_usable_candidate(goal, actor, candidate):
			continue
		if excluded_names.has(candidate.name):
			continue
		if needs_reservation and _is_reserved_by_other(actor_id, candidate):
			continue
		if needs_reservation and candidate.has_method("can_reserve") and not candidate.call("can_reserve", actor_id):
			continue

		var distance := actor.global_position.distance_to(candidate.global_position)
		var is_better := distance > best_distance if selection_mode == "farthest" else distance < best_distance
		if is_better:
			best_distance = distance
			best_target = candidate

	if best_target != null:
		if needs_reservation and best_target.has_method("reserve") and not bool(best_target.call("reserve", actor_id)):
			return null
		if needs_reservation:
			reservations[actor_id] = best_target.get_path()
		return best_target

	return null


func release(actor: Node3D, target: Node3D) -> void:
	if target != null and is_instance_valid(target) and target.has_method("release"):
		target.call("release", actor.name)
	reservations.erase(actor.name)


func _candidate_nodes_for_goal(goal: String) -> Array:
	if goal == "weapon":
		return get_tree().get_nodes_in_group("weapon_pickups")
	if goal == "combat":
		return get_tree().get_nodes_in_group("lyra_ai_combat_target")
	if goal == "explore":
		return get_tree().get_nodes_in_group("lyra_ai_waypoint")
	if goal == "build":
		return get_tree().get_nodes_in_group("lyra_ai_build_site")
	return get_tree().get_nodes_in_group("lyra_ai_target_%s" % goal)


func _is_usable_candidate(goal: String, actor: Node3D, candidate: Node3D) -> bool:
	if candidate.is_queued_for_deletion():
		return false
	if goal == "combat":
		var max_distance := float(actor.get("combat_seek_distance"))
		if max_distance > 0.0 and actor.global_position.distance_to(candidate.global_position) > max_distance:
			return false
		return not candidate.has_method("is_alive") or bool(candidate.call("is_alive"))
	if goal == "explore":
		if actor.has_method("get_next_explore_waypoint"):
			var waypoint_name := str(actor.call("get_next_explore_waypoint"))
			if waypoint_name != "" and candidate.name != waypoint_name:
				return false
		return true
	if goal == "build":
		if int(actor.get("resource_count")) <= 0:
			return false
		return candidate.has_method("needs_resources") and bool(candidate.call("needs_resources"))
	if goal != "weapon":
		return true
	if absf(candidate.global_position.y - actor.global_position.y) > 4.0:
		return false
	if candidate.get("pickup_enabled") == false:
		return false
	return candidate.get("weapon_resource") != null


func _is_reserved_by_other(actor_id: String, candidate: Node3D) -> bool:
	var candidate_path := str(candidate.get_path())
	for reserved_actor in reservations.keys():
		if str(reserved_actor) == actor_id:
			continue
		if str(reservations[reserved_actor]) == candidate_path:
			return true
	return false
