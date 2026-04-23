#!/usr/bin/env python3
"""Summarize training evolution logs and emit coach suggestions."""

from __future__ import annotations

import argparse
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean, pstdev
from typing import Any


PARAM_RANGES: dict[str, tuple[float, float]] = {
    "move_speed": (1.0, 7.0),
    "detection_range": (3.0, 16.0),
    "wander_radius": (1.0, 8.0),
    "shoot_cooldown": (0.4, 4.0),
    "shoot_spread": (0.0, 0.25),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Summarize Godot evolution_log.jsonl output.")
    parser.add_argument("--log", required=True, help="Path to evolution JSONL log.")
    parser.add_argument("--window", type=int, default=8, help="Rolling window for trend/stagnation checks.")
    parser.add_argument("--cycle", type=int, default=0, help="Cycle index for report metadata.")
    parser.add_argument("--summary-json", help="Optional path to write machine-readable summary JSON.")
    parser.add_argument("--summary-md", help="Optional path to write markdown report.")
    parser.add_argument(
        "--suggestions-path",
        help="Optional path to write evolution_suggestions.json for next run.",
    )
    return parser.parse_args()


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            rows.append(obj)
    return rows


def clamp(name: str, value: float) -> float:
    lo, hi = PARAM_RANGES[name]
    return max(lo, min(hi, value))


def role_scores(rows: list[dict[str, Any]], role: str) -> list[float]:
    out: list[float] = []
    for row in rows:
        role_data = (row.get("roles") or {}).get(role) or {}
        scores = role_data.get("scores") or []
        if isinstance(scores, list) and scores:
            try:
                out.append(float(scores[0]))
            except (TypeError, ValueError):
                pass
    return out


def latest_best_params(rows: list[dict[str, Any]], role: str) -> dict[str, float]:
    for row in reversed(rows):
        role_data = (row.get("roles") or {}).get(role) or {}
        params = role_data.get("best_params") or {}
        if isinstance(params, dict) and params:
            return {k: float(v) for k, v in params.items() if isinstance(v, (int, float))}
    return {}


def build_suggestion(role: str, params: dict[str, float], stagnating: bool, trend: float) -> dict[str, float]:
    if not params:
        return {}
    if not stagnating and trend > 2.0:
        return {}

    out = dict(params)
    if role == "enemy":
        if "move_speed" in out:
            out["move_speed"] = clamp("move_speed", out["move_speed"] * 1.08)
        if "detection_range" in out:
            out["detection_range"] = clamp("detection_range", out["detection_range"] + 0.8)
        if "shoot_cooldown" in out:
            out["shoot_cooldown"] = clamp("shoot_cooldown", out["shoot_cooldown"] * 0.92)
        if "shoot_spread" in out:
            out["shoot_spread"] = clamp("shoot_spread", out["shoot_spread"] * 0.85)
    elif role == "citizen":
        if "move_speed" in out:
            out["move_speed"] = clamp("move_speed", out["move_speed"] * 1.08)
        if "detection_range" in out:
            out["detection_range"] = clamp("detection_range", out["detection_range"] + 0.6)
        if "wander_radius" in out:
            out["wander_radius"] = clamp("wander_radius", out["wander_radius"] + 0.5)
    elif role == "companion":
        if "move_speed" in out:
            out["move_speed"] = clamp("move_speed", out["move_speed"] * 1.06)
        if "detection_range" in out:
            out["detection_range"] = clamp("detection_range", out["detection_range"] + 0.6)
        if "shoot_cooldown" in out:
            out["shoot_cooldown"] = clamp("shoot_cooldown", out["shoot_cooldown"] * 0.92)
        if "shoot_spread" in out:
            out["shoot_spread"] = clamp("shoot_spread", out["shoot_spread"] * 0.9)
    return out


def analyze(rows: list[dict[str, Any]], window: int) -> dict[str, Any]:
    now = datetime.now(timezone.utc).isoformat()
    roles = ["enemy", "citizen", "companion"]
    latest_generation = 0
    if rows:
        latest_generation = int(rows[-1].get("generation", 0))

    role_metrics: dict[str, Any] = {}
    suggestions: dict[str, Any] = {}
    gaps: list[str] = []

    for role in roles:
        scores = role_scores(rows, role)
        if not scores:
            role_metrics[role] = {"has_data": False}
            gaps.append(f"{role}: missing scores in evolution log")
            continue

        window_scores = scores[-window:] if len(scores) >= window else scores[:]
        first = float(window_scores[0])
        latest = float(window_scores[-1])
        trend = latest - first
        stdev = float(pstdev(window_scores)) if len(window_scores) > 1 else 0.0
        avg = float(mean(window_scores))
        stagnating = len(window_scores) >= 3 and abs(trend) < 1.0
        volatile = stdev > max(5.0, abs(avg) * 0.2)

        metrics = {
            "has_data": True,
            "samples": len(scores),
            "latest_best": latest,
            "window_mean": avg,
            "window_stdev": stdev,
            "window_first": first,
            "window_trend": trend,
            "stagnating": stagnating,
            "volatile": volatile,
            "best_params": latest_best_params(rows, role),
        }
        role_metrics[role] = metrics

        suggestion = build_suggestion(role, metrics["best_params"], stagnating, trend)
        if suggestion:
            suggestions[role] = suggestion

        if stagnating:
            gaps.append(f"{role}: score trend is flat over last {len(window_scores)} generations")
        if trend < 0:
            gaps.append(f"{role}: regression detected (trend {trend:.2f})")
        if volatile:
            gaps.append(f"{role}: high variance in recent generations (stdev {stdev:.2f})")

    if latest_generation == 0:
        gaps.append("No generations found; run headless training first.")
    if not suggestions:
        gaps.append("No coach suggestions generated; consider broadening mutation rate or scenario diversity.")

    return {
        "generated_at_utc": now,
        "generations_total": len(rows),
        "latest_generation": latest_generation,
        "window": window,
        "role_metrics": role_metrics,
        "research_gaps": gaps,
        "coach_suggestions": suggestions,
    }


def to_markdown(summary: dict[str, Any], cycle: int) -> str:
    lines: list[str] = []
    header = f"# Research Cycle {cycle} Summary" if cycle > 0 else "# Research Summary"
    lines.append(header)
    lines.append("")
    lines.append(f"- Generated (UTC): `{summary['generated_at_utc']}`")
    lines.append(f"- Generations logged: `{summary['generations_total']}`")
    lines.append(f"- Latest generation: `{summary['latest_generation']}`")
    lines.append(f"- Analysis window: `{summary['window']}`")
    lines.append("")
    lines.append("## Role Metrics")
    lines.append("")
    for role, metrics in summary["role_metrics"].items():
        lines.append(f"### {role}")
        if not metrics.get("has_data"):
            lines.append("- No data found")
            lines.append("")
            continue
        lines.append(f"- Latest best score: `{metrics['latest_best']:.2f}`")
        lines.append(f"- Window mean: `{metrics['window_mean']:.2f}`")
        lines.append(f"- Window trend: `{metrics['window_trend']:.2f}`")
        lines.append(f"- Window stdev: `{metrics['window_stdev']:.2f}`")
        lines.append(f"- Stagnating: `{metrics['stagnating']}`")
        lines.append(f"- Volatile: `{metrics['volatile']}`")
        lines.append("")
    lines.append("## Research Gaps")
    lines.append("")
    for gap in summary["research_gaps"]:
        lines.append(f"- {gap}")
    lines.append("")
    lines.append("## Coach Suggestions")
    lines.append("")
    if not summary["coach_suggestions"]:
        lines.append("- No override suggestions this cycle")
    else:
        for role, params in summary["coach_suggestions"].items():
            lines.append(f"- `{role}`: `{json.dumps(params, sort_keys=True)}`")
    lines.append("")
    return "\n".join(lines)


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def main() -> int:
    args = parse_args()
    rows = read_jsonl(Path(args.log))
    summary = analyze(rows, max(2, args.window))

    if args.summary_json:
        write_json(Path(args.summary_json), summary)
    if args.summary_md:
        md = to_markdown(summary, args.cycle)
        out = Path(args.summary_md)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(md, encoding="utf-8")
    if args.suggestions_path:
        write_json(Path(args.suggestions_path), summary["coach_suggestions"])

    print(
        "Summary ready: generations=%d latest=%d suggestions=%d"
        % (
            summary["generations_total"],
            summary["latest_generation"],
            len(summary["coach_suggestions"]),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
