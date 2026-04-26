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

    interaction_results: dict[str, Counter[str]] = defaultdict(Counter)
    for event in interactions:
        goal = str(event.get("goal", "unknown"))
        result = str(event.get("result", "unknown"))
        interaction_results[goal][result] += 1

    reservation_results = Counter(str(event.get("result", "unknown")) for event in reservations)
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
        "stuck_event_count": len(stuck_events),
        "max_stuck_seconds": round(max(stuck_seconds), 4) if stuck_seconds else 0.0,
        "average_frame_time_ms": round(mean(frame_times), 4) if frame_times else None,
        "worst_frame_time_ms": round(max(frame_times), 4) if frame_times else None,
        "simple_loop_score": round((success_count * 10.0) - (len(stuck_events) * 3.0) - (failure_count * 2.0) - avg_frame_penalty, 4),
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
