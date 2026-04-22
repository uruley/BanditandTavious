#!/usr/bin/env python3
"""Convert BanditAI JSONL activity logs into SQLite tables."""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path
from typing import Dict, Iterable, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Convert BanditAI JSONL logs to SQLite")
    parser.add_argument(
        "--input",
        default="bandit_ai_activity.jsonl",
        help="Path to JSONL activity log (default: bandit_ai_activity.jsonl)",
    )
    parser.add_argument(
        "--db",
        default="logs/bandit_ai_activity.db",
        help="Output SQLite database path (default: logs/bandit_ai_activity.db)",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Drop and recreate tables before import",
    )
    return parser.parse_args()


def ensure_schema(conn: sqlite3.Connection, reset: bool) -> None:
    cur = conn.cursor()
    if reset:
        cur.executescript(
            """
            DROP TABLE IF EXISTS actor_samples;
            DROP TABLE IF EXISTS actor_transitions;
            """
        )

    cur.executescript(
        """
        CREATE TABLE IF NOT EXISTS actor_samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp_ms INTEGER NOT NULL,
            scene TEXT NOT NULL,
            actor_name TEXT NOT NULL,
            role INTEGER NOT NULL,
            state TEXT NOT NULL,
            pos_x REAL NOT NULL,
            pos_y REAL NOT NULL,
            pos_z REAL NOT NULL,
            vel_x REAL NOT NULL,
            vel_y REAL NOT NULL,
            vel_z REAL NOT NULL,
            target_x REAL NOT NULL,
            target_y REAL NOT NULL,
            target_z REAL NOT NULL,
            target_name TEXT NOT NULL,
            distance_to_target REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS actor_transitions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actor_name TEXT NOT NULL,
            role INTEGER NOT NULL,
            t0_ms INTEGER NOT NULL,
            t1_ms INTEGER NOT NULL,
            dt_seconds REAL NOT NULL,
            s0_state TEXT NOT NULL,
            s1_state TEXT NOT NULL,
            s0_distance_to_target REAL NOT NULL,
            s1_distance_to_target REAL NOT NULL,
            action_dx REAL NOT NULL,
            action_dz REAL NOT NULL,
            speed_mps REAL NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_actor_samples_actor_time
            ON actor_samples(actor_name, timestamp_ms);
        CREATE INDEX IF NOT EXISTS idx_actor_transitions_actor_time
            ON actor_transitions(actor_name, t0_ms);
        """
    )
    conn.commit()


def _vector3(data: Dict, key: str) -> Tuple[float, float, float]:
    v = data.get(key, {})
    return float(v.get("x", 0.0)), float(v.get("y", 0.0)), float(v.get("z", 0.0))


def iter_rows(path: Path) -> Iterable[Dict]:
    with path.open("r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                payload = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON at line {line_number}: {exc}") from exc
            yield payload


def import_rows(conn: sqlite3.Connection, rows: Iterable[Dict]) -> Tuple[int, int]:
    cur = conn.cursor()
    sample_count = 0
    transition_count = 0
    last_by_actor: Dict[str, Dict] = {}

    for payload in rows:
        timestamp_ms = int(payload.get("timestamp_ms", 0))
        scene = str(payload.get("scene", ""))
        actors = payload.get("actors", [])

        for actor in actors:
            actor_name = str(actor.get("name", ""))
            role = int(actor.get("role", -1))
            state = str(actor.get("state", "unknown"))
            pos_x, pos_y, pos_z = _vector3(actor, "position")
            vel_x, vel_y, vel_z = _vector3(actor, "velocity")
            tgt_x, tgt_y, tgt_z = _vector3(actor, "target_point")
            target_name = str(actor.get("target_name", ""))
            dist = float(actor.get("distance_to_target", 0.0))

            cur.execute(
                """
                INSERT INTO actor_samples(
                    timestamp_ms, scene, actor_name, role, state,
                    pos_x, pos_y, pos_z, vel_x, vel_y, vel_z,
                    target_x, target_y, target_z, target_name, distance_to_target
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    timestamp_ms,
                    scene,
                    actor_name,
                    role,
                    state,
                    pos_x,
                    pos_y,
                    pos_z,
                    vel_x,
                    vel_y,
                    vel_z,
                    tgt_x,
                    tgt_y,
                    tgt_z,
                    target_name,
                    dist,
                ),
            )
            sample_count += 1

            prev = last_by_actor.get(actor_name)
            if prev is not None and timestamp_ms > prev["timestamp_ms"]:
                dt = (timestamp_ms - prev["timestamp_ms"]) / 1000.0
                action_dx = pos_x - prev["pos_x"]
                action_dz = pos_z - prev["pos_z"]
                speed = ((action_dx * action_dx + action_dz * action_dz) ** 0.5) / dt
                cur.execute(
                    """
                    INSERT INTO actor_transitions(
                        actor_name, role, t0_ms, t1_ms, dt_seconds,
                        s0_state, s1_state, s0_distance_to_target, s1_distance_to_target,
                        action_dx, action_dz, speed_mps
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        actor_name,
                        role,
                        prev["timestamp_ms"],
                        timestamp_ms,
                        dt,
                        prev["state"],
                        state,
                        prev["distance_to_target"],
                        dist,
                        action_dx,
                        action_dz,
                        speed,
                    ),
                )
                transition_count += 1

            last_by_actor[actor_name] = {
                "timestamp_ms": timestamp_ms,
                "pos_x": pos_x,
                "pos_z": pos_z,
                "state": state,
                "distance_to_target": dist,
            }

    conn.commit()
    return sample_count, transition_count


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)
    db_path = Path(args.db)
    db_path.parent.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        print(f"Input log not found: {input_path}")
        print("Run BanditAI scene first so logger creates user://bandit_ai_activity.jsonl")
        return 1

    conn = sqlite3.connect(db_path)
    try:
        ensure_schema(conn, args.reset)
        samples, transitions = import_rows(conn, iter_rows(input_path))
    finally:
        conn.close()

    print(f"Wrote SQLite DB: {db_path}")
    print(f"Imported samples: {samples}")
    print(f"Imported transitions: {transitions}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
