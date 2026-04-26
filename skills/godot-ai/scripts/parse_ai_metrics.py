#!/usr/bin/env python3
"""Summarize BanditandTavious AI JSONL metrics."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean
from typing import Any


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue
        try:
            event = json.loads(stripped)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"{path}:{line_number}: invalid JSON: {exc}") from exc
        if isinstance(event, dict):
            events.append(event)
    return events


def summarize(events: list[dict[str, Any]]) -> dict[str, Any]:
    event_types = Counter(str(event.get("type", "unknown")) for event in events)
    decisions = [event for event in events if event.get("type") == "decision"]
    interactions = [event for event in events if event.get("type") == "interaction_complete"]
    stuck_events = [event for event in events if event.get("type") == "stuck"]
    reservations = [event for event in events if event.get("type") == "reservation"]
    frame_samples = [event for event in events if event.get("type") == "frame_sample"]
    shots = [event for event in events if event.get("type") == "shot_fired"]
    route_visits = [event for event in events if event.get("type") == "route_visit"]
    build_events = [event for event in events if str(event.get("type", "")).startswith("build_")]
    build_completed = [event for event in events if event.get("type") == "build_completed"]
    lifecycle_types = {
        "goal_selected",
        "goal_started",
        "goal_completed",
        "goal_failed",
        "goal_cleanup",
        "reservation_released",
        "next_goal_selected",
    }
    lifecycle_events = [event for event in events if str(event.get("type", "")) in lifecycle_types]
    goal_selected = [event for event in events if event.get("type") == "goal_selected"]
    goal_started = [event for event in events if event.get("type") == "goal_started"]
    goal_completed = [event for event in events if event.get("type") == "goal_completed"]
    goal_failed = [event for event in events if event.get("type") == "goal_failed"]
    goal_cleanup = [event for event in events if event.get("type") == "goal_cleanup"]
    lifecycle_reservation_released = [
        event for event in events if event.get("type") == "reservation_released"
    ]
    next_goal_selected = [event for event in events if event.get("type") == "next_goal_selected"]
    idle_timeouts = [event for event in events if event.get("type") == "actor_idle_timeout"]

    interaction_results: dict[str, Counter[str]] = defaultdict(Counter)
    for event in interactions:
        goal = str(event.get("goal", "unknown"))
        result = str(event.get("result", "unknown"))
        interaction_results[goal][result] += 1

    reservation_results = Counter(str(event.get("result", "unknown")) for event in reservations)
    shot_results = Counter(str(event.get("result", "unknown")) for event in shots)
    visited_waypoints = Counter(str(event.get("target", "unknown")) for event in route_visits)
    route_visits_by_actor = Counter(str(event.get("actor", "unknown")) for event in route_visits)
    build_event_types = Counter(str(event.get("type", "unknown")) for event in build_events)
    built_sites = Counter(str(event.get("target", "unknown")) for event in build_completed)
    goal_failed_reasons = Counter(str(event.get("reason", "unknown")) for event in goal_failed)
    lifecycle_by_actor: dict[str, Counter[str]] = defaultdict(Counter)
    lifecycle_by_goal: dict[str, Counter[str]] = defaultdict(Counter)
    lifecycle_by_id: dict[tuple[str, int], dict[str, Any]] = {}
    for event in lifecycle_events:
        event_type = str(event.get("type", "unknown"))
        actor = str(event.get("actor", "unknown"))
        goal = str(event.get("goal", "unknown"))
        lifecycle_by_actor[actor][event_type] += 1
        lifecycle_by_goal[goal][event_type] += 1
        raw_goal_id = event.get("goal_id")
        if not isinstance(raw_goal_id, int | float):
            continue
        goal_id = int(raw_goal_id)
        if goal_id <= 0:
            continue
        key = (actor, goal_id)
        record = lifecycle_by_id.setdefault(
            key,
            {
                "actor": actor,
                "goal_id": goal_id,
                "goal": goal,
                "target": str(event.get("target", "")),
                "types": set(),
            },
        )
        record["types"].add(event_type)
        if goal and goal != "unknown":
            record["goal"] = goal
        target = str(event.get("target", ""))
        if target:
            record["target"] = target

    unfinished_goals = []
    for record in lifecycle_by_id.values():
        types = record["types"]
        if "goal_started" in types and "goal_completed" not in types and "goal_failed" not in types:
            unfinished_goals.append(
                {
                    "actor": record["actor"],
                    "goal_id": record["goal_id"],
                    "goal": record["goal"],
                    "target": record["target"],
                    "types": sorted(types),
                }
            )

    shot_count = len(shots)
    shot_hit_count = shot_results.get("hit", 0)
    shot_accuracy = float(shot_hit_count) / float(shot_count) if shot_count else 0.0
    frame_times = [
        float(event["frame_time_ms"])
        for event in frame_samples
        if isinstance(event.get("frame_time_ms"), int | float)
    ]
    scores = [
        float(event["score"])
        for event in decisions
        if isinstance(event.get("score"), int | float)
    ]
    stuck_seconds = [
        float(event["stuck_seconds"])
        for event in stuck_events
        if isinstance(event.get("stuck_seconds"), int | float)
    ]

    success_count = sum(
        1
        for event in interactions
        if str(event.get("result", "")).lower() == "success"
    )
    failure_count = sum(count for result, count in reservation_results.items() if result.lower() != "success")
    avg_frame_penalty = max(0.0, (mean(frame_times) - 16.67) / 5.0) if frame_times else 0.0

    return {
        "total_events": len(events),
        "event_types": dict(event_types),
        "decisions_by_goal": dict(Counter(str(event.get("goal", "unknown")) for event in decisions)),
        "average_decision_score": round(mean(scores), 4) if scores else None,
        "interactions": {goal: dict(counter) for goal, counter in interaction_results.items()},
        "reservation_results": dict(reservation_results),
        "goal_selected_count": len(goal_selected),
        "goal_started_count": len(goal_started),
        "goal_completed_count": len(goal_completed),
        "goal_failed_count": len(goal_failed),
        "goal_cleanup_count": len(goal_cleanup),
        "lifecycle_reservation_released_count": len(lifecycle_reservation_released),
        "next_goal_selected_count": len(next_goal_selected),
        "actor_idle_timeout_count": len(idle_timeouts),
        "goal_failed_reasons": dict(goal_failed_reasons),
        "goal_lifecycle_by_actor": {
            actor: dict(counter) for actor, counter in lifecycle_by_actor.items()
        },
        "goal_lifecycle_by_goal": {
            goal: dict(counter) for goal, counter in lifecycle_by_goal.items()
        },
        "unfinished_goal_count": len(unfinished_goals),
        "unfinished_goals": unfinished_goals[:20],
        "shot_results": dict(shot_results),
        "shot_count": shot_count,
        "shot_hit_count": shot_hit_count,
        "shot_accuracy": round(shot_accuracy, 4),
        "stuck_event_count": len(stuck_events),
        "route_visit_count": len(route_visits),
        "unique_waypoint_count": len(visited_waypoints),
        "visited_waypoints": dict(visited_waypoints),
        "route_visits_by_actor": dict(route_visits_by_actor),
        "build_event_count": len(build_events),
        "build_completed_count": len(build_completed),
        "build_event_types": dict(build_event_types),
        "built_sites": dict(built_sites),
        "max_stuck_seconds": round(max(stuck_seconds), 4) if stuck_seconds else 0.0,
        "average_frame_time_ms": round(mean(frame_times), 4) if frame_times else None,
        "worst_frame_time_ms": round(max(frame_times), 4) if frame_times else None,
        "simple_loop_score": round((success_count * 10.0) + (shot_hit_count * 4.0) + (len(route_visits) * 5.0) + (len(build_completed) * 25.0) + (build_event_types.get("build_resource_delivered", 0) * 5.0) - (len(stuck_events) * 3.0) - (failure_count * 2.0) - avg_frame_penalty, 4),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log_path", type=Path, help="Path to AI metrics JSONL log.")
    parser.add_argument("--json", action="store_true", help="Print compact JSON only.")
    args = parser.parse_args()

    events = load_events(args.log_path)
    summary = summarize(events)

    if args.json:
        print(json.dumps(summary, sort_keys=True))
    else:
        print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
