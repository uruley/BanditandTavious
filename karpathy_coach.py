"""
Karpathy autoresearch loop — NPC pickup behavior.

Single file : level/scripts/karpathy_agent.gd   (Qwen3 rewrites this)
Metric      : pickups_collected                  (written by Godot, hard number)
Keep/revert : score up = keep new script, score down = revert to last best
"""

import json
import re
import subprocess
import time
import requests
from pathlib import Path

MODEL       = "qwen3:8b"
OLLAMA_URL  = "http://localhost:11434/api/generate"
MAX_RUNS    = 10
GODOT_EXE   = r"C:\Users\ruley\CornersstoneGamingEngine\Godot\Godot_v4.3-stable_win64.exe"
PROJECT     = Path(r"C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious")
AGENT       = PROJECT / "level" / "scripts" / "karpathy_agent.gd"
RESULT      = Path(r"C:\Users\ruley\AppData\Roaming\Godot\app_userdata\godot-3d-multiplayer-enhanced") / "episode_result.json"
SCENE       = "res://level/scenes/KarpathyArena.tscn"
LOG         = PROJECT / "logs" / "karpathy_coach.log"

SYSTEM = """\
You are an expert GDScript 4 coder. Rewrite a Godot 4.3 CharacterBody3D script so an NPC \
collects all 8 Area3D pickup nodes as FAST as possible. The episode ends early when all \
pickups are collected — speed is the metric.

ARENA: flat 20x20 floor. 6 box pillars (1.5x1.5x1.5) placed at fixed spots block direct \
paths. Pickup positions are RANDOM each run — the agent cannot memorize them. \
The agent must navigate around pillars and plan efficient routes.

YOUR SCRIPT MUST USE THIS EXACT STRUCTURE (do not omit _ready):

extends CharacterBody3D

# your constants here

# your variables here

func _ready() -> void:
\tadd_to_group("karpathy_agent")
\t# any other setup

func _physics_process(delta: float) -> void:
\tvelocity.y -= 18.0 * delta
\t# your movement logic here
\tmove_and_slide()

# your helper functions here

MANDATORY RULES — violation = script won't run:
  1. First line: extends CharacterBody3D
  2. func _ready() must exist and call add_to_group("karpathy_agent")
  3. func _physics_process(delta) must have: velocity.y -= 18.0 * delta  AND  move_and_slide()
  4. GDScript 4 only — no C# syntax

GDSCRIPT 4 SYNTAX RULES (violations cause parse errors):
  - Type inference (:=) only works when the right side has a clear type.
    Use explicit types for nullable values: var x: Vector3 = some_func()
  - Math functions: use abs(), min(), max(), sqrt(), sin(), cos(), atan2() — NOT Mathf.*
  - Rotation: use rotation.y — NOT rotation_y
  - Time: use Time.get_ticks_msec() — NOT get_time() or OS.get_ticks_msec()
  - Angles: use wrapf(angle, -PI, PI) — NOT Mathf.LerpAngle
  - Random: use randf(), randi(), randf_range(a,b) — NOT Random.Range
  - No semicolons at end of lines
  - String format: "text %d" % value — NOT f"text {value}"
  - Node path: $CollisionShape3D — NOT GetChild or FindChild

ARENA FACTS:
  - Pickups are Area3D nodes in group "pickup". Skip if not .visible (already collected).
  - get_tree().get_nodes_in_group("pickup") returns all pickups
  - Arena floor is at y=0. Walls at x=±10, z=±10.
  - Agent spawns at Vector3(0, 1, 0)

Respond with ONLY the raw GDScript. No markdown, no fences, no explanation."""


# Patterns that indicate Qwen3 generated non-GDScript syntax
BAD_PATTERNS = [
    r"\bMathf\b",           # C# Math class
    r"\brotation_y\b",      # wrong — should be rotation.y
    r"\bget_time\(\)",      # doesn't exist
    r"\bRandom\.Range\b",   # Unity/C#
    r"\bGetChild\b",        # C# style
    r"\bVector3\.Lerp\b",   # C# style
    r"\bDebug\.Log\b",      # Unity
    r";\s*$",               # trailing semicolons (multiline)
    r"\*[a-zA-Z_]",         # Python-style unpack (*args, *variable)
    r"\*\*",                # Python kwargs (**)
    r"def ",                # Python function syntax
]


def validate_script(script: str) -> tuple[bool, str]:
    if not script.startswith("extends CharacterBody3D"):
        return False, "must start with 'extends CharacterBody3D'"
    if "move_and_slide" not in script:
        return False, "missing 'move_and_slide'"
    if "velocity.y" not in script:
        return False, "missing gravity (velocity.y)"
    # add_to_group must be inside a function, not at class body level
    if "func _ready" not in script:
        return False, "missing 'func _ready()'"
    # Check add_to_group appears after func _ready, not before
    ready_pos = script.find("func _ready")
    group_pos = script.find("add_to_group")
    if group_pos == -1:
        return False, "missing 'add_to_group'"
    if group_pos < ready_pos:
        return False, "add_to_group must be inside _ready(), not at class level"
    for pattern in BAD_PATTERNS:
        if re.search(pattern, script, re.MULTILINE):
            return False, f"bad pattern: {pattern}"
    return True, "ok"


def godot_parse_check() -> tuple[bool, str]:
    """Run Godot for 8s to catch parse errors before wasting a full episode."""
    try:
        result = subprocess.run(
            [GODOT_EXE, "--headless", "--path", str(PROJECT), SCENE],
            capture_output=True, text=True, timeout=8,
        )
        combined = (result.stdout or "") + (result.stderr or "")
    except subprocess.TimeoutExpired as exc:
        # Still running after 8s = no crash = script is valid
        combined = ""
        if exc.stdout:
            combined += exc.stdout.decode(errors="replace")
        if exc.stderr:
            combined += exc.stderr.decode(errors="replace")

    if "SCRIPT ERROR: Parse Error" in combined and "karpathy_agent.gd" in combined:
        for line in combined.splitlines():
            if "Parse Error" in line:
                return False, line.strip()[:120]
        return False, "GDScript parse error"
    return True, "ok"


def log(msg: str) -> None:
    LOG.parent.mkdir(exist_ok=True)
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def run_episode() -> int:
    if RESULT.exists():
        RESULT.unlink()
    log("Launching Godot headless...")
    try:
        subprocess.run(
            [GODOT_EXE, "--headless", "--path", str(PROJECT), SCENE],
            timeout=90,
        )
    except subprocess.TimeoutExpired:
        log("Godot timed out.")
        return 0

    if not RESULT.exists():
        log("No result file — episode may have crashed.")
        return 0

    data = json.loads(RESULT.read_text(encoding="utf-8"))
    score = data.get("score", 0)          # composite: pickups*100 + time_remaining
    collected = data.get("pickups_collected", 0)
    total = data.get("total_pickups", 8)
    time_used = data.get("time_used", 60)
    log(f"Score: {score:.1f}  ({collected}/{total} pickups in {time_used:.1f}s)")
    return score


def rewrite(script: str, score: int, best: int, run: int) -> str:
    prompt = (
        f"Run {run} result: composite score {score:.1f} (best so far: {best:.1f}).\n"
        f"Score = pickups_collected * 100 + seconds_remaining. Max = 860.\n"
        f"Pickup positions are RANDOM each run. 6 box pillars block direct paths.\n\n"
        f"Current WORKING script:\n{script}\n\n"
        f"Make ONE small improvement to this script. Do NOT add path generation, do NOT call "
        f"any function with a possibly-null variable. Keep _ready() simple. "
        f"Suggested improvements: better pickup ordering, avoid unnecessary backtracking, "
        f"slight speed tweaks. Return the complete script with your change."
    )
    resp = requests.post(OLLAMA_URL, json={
        "model": MODEL,
        "system": SYSTEM,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0.3},
        "think": False,
    }, timeout=180)
    resp.raise_for_status()
    return resp.json().get("response", "").strip()


def main() -> None:
    log(f"=== Karpathy loop — {MAX_RUNS} runs ===")

    best_score  = -1
    best_script = AGENT.read_text(encoding="utf-8")

    for run in range(1, MAX_RUNS + 1):
        log(f"\n--- Run {run} / {MAX_RUNS} ---")

        score = run_episode()

        if score == 0.0:
            log("Score is 0 — script likely crashed at runtime, reverting without rewrite")
            AGENT.write_text(best_script, encoding="utf-8")
            if run == MAX_RUNS:
                break
            continue

        if score > best_score:
            best_score  = score
            best_script = AGENT.read_text(encoding="utf-8")
            log(f"New best: {best_score:.1f} — script saved")
        else:
            log(f"No improvement ({score:.1f} <= {best_score:.1f}) — reverting script")
            AGENT.write_text(best_script, encoding="utf-8")

        if run == MAX_RUNS:
            break

        log("Calling Qwen3 for next script...")
        try:
            new_script = rewrite(AGENT.read_text(encoding="utf-8"), score, best_score, run)

            ok, reason = validate_script(new_script)
            if not ok:
                log(f"Regex validation failed ({reason}) — keeping current script")
            else:
                AGENT.write_text(new_script, encoding="utf-8")
                log("Checking script parses in Godot (~8s)...")
                parse_ok, parse_reason = godot_parse_check()
                if parse_ok:
                    log("Script valid. Preview:")
                    log(new_script[:500] + ("..." if len(new_script) > 500 else ""))
                else:
                    log(f"Godot parse error: {parse_reason} — reverting to best")
                    AGENT.write_text(best_script, encoding="utf-8")
        except Exception as e:
            log(f"Qwen3 error: {e}")

    log(f"\n=== Done. Best composite score: {best_score:.1f} ===")


if __name__ == "__main__":
    main()
