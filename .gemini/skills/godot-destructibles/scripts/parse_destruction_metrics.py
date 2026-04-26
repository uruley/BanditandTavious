#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path


PREFIX = "DESTRUCTION_METRICS "

PRESETS = {
    "sphere": {
        "min_shards": 8,
        "max_spread": 4.0,
        "max_post_delta": 0.02,
        "require_height_drop": True,
    },
    "wall": {
        "min_shards": 4,
        "max_spread": 8.0,
        "max_post_delta": 0.025,
        "require_height_drop": False,
    },
    "pillar": {
        "min_shards": 8,
        "max_spread": 6.0,
        "max_post_delta": 0.025,
        "require_height_drop": True,
    },
}


def load_metrics(log_path: Path) -> list[dict]:
    metrics: list[dict] = []
    for raw_line in log_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line.startswith(PREFIX):
            continue
        payload = line[len(PREFIX) :]
        metrics.append(json.loads(payload))
    return metrics


def summarize(metrics: list[dict]) -> dict:
    first = metrics[0]
    last = metrics[-1]
    benchmark_label = last.get("benchmark_label", first.get("benchmark_label", "unknown"))
    shard_count = last.get("shard_count", 0)
    impact_detected = any(item.get("impact_detected") for item in metrics)
    max_spread = max(float(item.get("max_shard_distance_from_target_origin", 0.0)) for item in metrics)
    avg_height_start = float(first.get("average_shard_height", 0.0))
    avg_height_end = float(last.get("average_shard_height", 0.0))
    pre_delta = float(last.get("pre_impact_avg_delta", first.get("pre_impact_avg_delta", -1.0)))
    post_delta = float(last.get("post_impact_avg_delta", first.get("post_impact_avg_delta", -1.0)))
    return {
        "benchmark_label": benchmark_label,
        "samples": len(metrics),
        "impact_detected": impact_detected,
        "shard_count": shard_count,
        "max_spread": max_spread,
        "average_height_start": avg_height_start,
        "average_height_end": avg_height_end,
        "pre_impact_avg_delta": pre_delta,
        "post_impact_avg_delta": post_delta,
        "labels": [item.get("label", "") for item in metrics],
    }


def evaluate(summary: dict, args: argparse.Namespace) -> tuple[bool, list[str]]:
    failures: list[str] = []

    if not summary["impact_detected"]:
        failures.append("impact was not detected")

    if args.min_shards is not None and summary["shard_count"] < args.min_shards:
        failures.append(f"shard_count {summary['shard_count']} < min_shards {args.min_shards}")

    if args.max_spread is not None and summary["max_spread"] > args.max_spread:
        failures.append(f"max_spread {summary['max_spread']:.3f} > max_spread {args.max_spread}")

    if args.max_post_delta is not None:
        post_delta = summary["post_impact_avg_delta"]
        if post_delta < 0 or post_delta > args.max_post_delta:
            failures.append(
                f"post_impact_avg_delta {post_delta:.6f} > max_post_delta {args.max_post_delta}"
            )

    if args.require_height_drop:
        if summary["average_height_end"] >= summary["average_height_start"]:
            failures.append(
                "average shard height did not decrease between first and last metric sample"
            )

    return (len(failures) == 0, failures)


def main() -> int:
    parser = argparse.ArgumentParser(description="Parse DESTRUCTION_METRICS lines from a Godot log.")
    parser.add_argument("log_path", type=Path, help="Path to the Godot log file")
    parser.add_argument(
        "--preset",
        choices=sorted(PRESETS.keys()),
        default=None,
        help="Apply built-in thresholds for a common destructible type",
    )
    parser.add_argument("--min-shards", type=int, default=None, help="Fail if shard_count is below this")
    parser.add_argument("--max-spread", type=float, default=None, help="Fail if max spread exceeds this")
    parser.add_argument(
        "--max-post-delta",
        type=float,
        default=None,
        help="Fail if post-impact average delta exceeds this",
    )
    parser.add_argument(
        "--require-height-drop",
        action="store_true",
        help="Fail if average shard height does not decrease from first to last sample",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the summary as JSON instead of plain text",
    )
    args = parser.parse_args()
    applied_preset = PRESETS.get(args.preset, {})
    for key, value in applied_preset.items():
        if key == "require_height_drop":
            args.require_height_drop = args.require_height_drop or bool(value)
        elif getattr(args, key) is None:
            setattr(args, key, value)

    if not args.log_path.exists():
        print(f"log file not found: {args.log_path}", file=sys.stderr)
        return 2

    metrics = load_metrics(args.log_path)
    if not metrics:
        print("no DESTRUCTION_METRICS lines found", file=sys.stderr)
        return 3

    summary = summarize(metrics)
    ok, failures = evaluate(summary, args)
    summary["ok"] = ok
    summary["failures"] = failures
    summary["preset"] = args.preset
    summary["thresholds"] = {
        "min_shards": args.min_shards,
        "max_spread": args.max_spread,
        "max_post_delta": args.max_post_delta,
        "require_height_drop": args.require_height_drop,
    }

    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        print(f"benchmark: {summary['benchmark_label']}")
        if args.preset:
            print(f"preset: {args.preset}")
        print(f"samples: {summary['samples']} ({', '.join(summary['labels'])})")
        print(f"impact_detected: {summary['impact_detected']}")
        print(f"shard_count: {summary['shard_count']}")
        print(f"max_spread: {summary['max_spread']:.3f}")
        print(
            "average_height: "
            f"{summary['average_height_start']:.3f} -> {summary['average_height_end']:.3f}"
        )
        print(
            "frame_delta: "
            f"{summary['pre_impact_avg_delta']:.6f} -> {summary['post_impact_avg_delta']:.6f}"
        )
        print("status: PASS" if ok else "status: FAIL")
        for failure in failures:
            print(f"- {failure}")

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
