"""
AI training coach — watches evolution_log.jsonl, calls a local Ollama model
every N generations, writes parameter suggestions back for Godot to pick up.
"""

import json
import time
import requests
from pathlib import Path

MODEL = "qwen3:8b"
OLLAMA_URL = "http://localhost:11434/api/generate"
COACH_INTERVAL = 5          # call LLM every N generations
POLL_SECONDS = 20           # how often to check the log file

USERDATA = Path(r"C:\Users\ruley\AppData\Roaming\Godot\app_userdata\godot-3d-multiplayer-enhanced")
EVOLUTION_LOG = USERDATA / "evolution_log.jsonl"
SUGGESTIONS_FILE = USERDATA / "evolution_suggestions.json"

SYSTEM_PROMPT = """\
You are a parameter tuning coach for a game AI training loop.

Three NPC types compete in a 40x40 arena each 60-second episode:
  enemy    — chases and shoots citizens/companions
             fitness = attacks_landed*8 + shots_hit*5 + accuracy*25 + distance*0.04
  citizen  — survives, collects pickups, flees enemies
             fitness = survival_time*1.5 + pickups*20 - time_near_threat*0.5
  companion— shoots enemies, collects pickups, defends near player
             fitness = shots_hit*10 + accuracy*30 + pickups*10 + time_defending*0.5

Parameter ranges (stay within these):
  move_speed:       1.0 – 7.0
  detection_range:  3.0 – 16.0
  wander_radius:    1.0 – 8.0
  shoot_cooldown:   0.4 – 4.0   (lower = shoots more often)
  shoot_spread:     0.0 – 0.25  (lower = more accurate)

Citizen does NOT have shoot_cooldown or shoot_spread.

Analyze the generation history and suggest the best seed parameters for the next generation.
Respond ONLY with valid JSON, no explanation, no markdown, in this exact structure:
{
  "enemy":     {"move_speed": 0.0, "detection_range": 0.0, "wander_radius": 0.0, "shoot_cooldown": 0.0, "shoot_spread": 0.0},
  "citizen":   {"move_speed": 0.0, "detection_range": 0.0, "wander_radius": 0.0},
  "companion": {"move_speed": 0.0, "detection_range": 0.0, "wander_radius": 0.0, "shoot_cooldown": 0.0, "shoot_spread": 0.0}
}"""


def read_recent(n: int = 15) -> list:
    if not EVOLUTION_LOG.exists():
        return []
    lines = EVOLUTION_LOG.read_text(encoding="utf-8").splitlines()
    return [json.loads(l) for l in lines[-n:] if l.strip()]


def build_prompt(generations: list) -> str:
    lines = []
    for gen in generations:
        g = gen.get("generation", "?")
        parts = [f"Gen {g}:"]
        for role, data in gen.get("roles", {}).items():
            scores = data.get("scores", [])
            best = max(scores) if scores else 0.0
            bp = data.get("best_params", {})
            parts.append(f"  {role} best={best:.1f} params={json.dumps(bp)}")
        lines.append("\n".join(parts))
    history = "\n".join(lines)
    return f"Generation history (most recent last):\n\n{history}\n\nSuggest parameters for the next generation."


def call_ollama(user_prompt: str) -> dict:
    payload = {
        "model": MODEL,
        "system": SYSTEM_PROMPT,
        "prompt": user_prompt,
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.4},
        "think": False,         # disable Qwen3 thinking tokens for speed
    }
    resp = requests.post(OLLAMA_URL, json=payload, timeout=180)
    resp.raise_for_status()
    raw = resp.json().get("response", "{}")
    return json.loads(raw)


def validate(suggestions: dict) -> bool:
    required = {
        "enemy":     {"move_speed", "detection_range", "wander_radius", "shoot_cooldown", "shoot_spread"},
        "citizen":   {"move_speed", "detection_range", "wander_radius"},
        "companion": {"move_speed", "detection_range", "wander_radius", "shoot_cooldown", "shoot_spread"},
    }
    for role, keys in required.items():
        if role not in suggestions:
            return False
        if not keys.issubset(suggestions[role].keys()):
            return False
    return True


def main() -> None:
    print(f"[Coach] Model   : {MODEL}")
    print(f"[Coach] Log     : {EVOLUTION_LOG}")
    print(f"[Coach] Output  : {SUGGESTIONS_FILE}")
    print(f"[Coach] Interval: every {COACH_INTERVAL} generations\n")

    last_gen = 0

    while True:
        time.sleep(POLL_SECONDS)

        generations = read_recent(15)
        if not generations:
            continue

        latest_gen = generations[-1].get("generation", 0)
        if latest_gen - last_gen < COACH_INTERVAL:
            continue

        print(f"[Coach] Gen {latest_gen} — querying {MODEL}...")
        try:
            prompt = build_prompt(generations)
            suggestions = call_ollama(prompt)

            if not validate(suggestions):
                print(f"[Coach] Bad response shape, skipping: {suggestions}")
                continue

            SUGGESTIONS_FILE.write_text(json.dumps(suggestions, indent=2), encoding="utf-8")
            last_gen = latest_gen
            print(f"[Coach] Suggestions written for gen {latest_gen + 1}:")
            for role, params in suggestions.items():
                print(f"  {role}: {params}")

        except Exception as exc:
            print(f"[Coach] Error: {exc}")


if __name__ == "__main__":
    main()
