"""
Karpathy autoresearch loop — Spartan dialogue edition.

Single modifiable file : dialogue.json
Metric                 : Qwen3 scores the exchange 1-10
Loop                   : score -> rewrite -> score -> rewrite ...
"""

import json
import time
import copy
import requests
from pathlib import Path

MODEL = "qwen3:8b"
OLLAMA_URL = "http://localhost:11434/api/generate"
PROJECT = Path(r"C:\Users\ruley\AppData\Roaming\Godot\app_userdata\BanditandTavious")
DIALOGUE_FILE = PROJECT / "dialogue.json"
LOG_FILE = PROJECT / "logs" / "dialogue_coach.log"
RUN_INTERVAL = 30       # seconds between iterations
MAX_ITERATIONS = 200

CONTEXT = """\
Two Spartan warriors — Leonidas (king, stoic, duty above all) and Dienekes \
(veteran soldier, darkly humorous, philosophical about death) — are camped \
the night before the Battle of Thermopylae (480 BC). They know they will hold \
the pass against the entire Persian army and almost certainly die. \
The dialogue should feel authentic to Spartan culture: brief, direct, no self-pity, \
dark wit, warrior's code, loyalty to Sparta above everything."""

SCORE_PROMPT = """\
{context}

Current dialogue (version {version}):
{dialogue}

Score this exchange from 1-10 on these criteria:
- Authenticity: sounds like real Spartan warriors (not Hollywood cliche)
- Character voice: Leonidas and Dienekes feel distinct
- Depth: goes beyond the obvious, reveals character or philosophy
- Dramatic tension: the weight of tomorrow is felt
- Progression: each line builds on the last

Respond ONLY with valid JSON:
{{"score": <float 1-10>, "critique": "<one sentence on biggest weakness>"}}"""

REWRITE_PROMPT = """\
{context}

Previous dialogue (version {version}, score {score}/10):
{dialogue}

Critique: {critique}

Rewrite and expand the dialogue. Keep what works, fix the weakness, add 1-3 more \
exchanges that deepen the conversation. Leonidas speaks first. End at a natural \
dramatic beat — do not resolve the tension, let it hang.

Respond ONLY with valid JSON:
{{"exchanges": [{{"speaker": "leonidas" or "dienekes", "line": "<line>"}}]}}"""


def load_dialogue() -> dict:
    return json.loads(DIALOGUE_FILE.read_text(encoding="utf-8"))


def save_dialogue(data: dict) -> None:
    DIALOGUE_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def call_ollama(prompt: str) -> dict:
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "options": {"temperature": 0.7},
        "think": False,
    }
    resp = requests.post(OLLAMA_URL, json=payload, timeout=120)
    resp.raise_for_status()
    return json.loads(resp.json().get("response", "{}"))


def format_dialogue(exchanges: list) -> str:
    return "\n".join(f"  {e['speaker'].upper()}: \"{e['line']}\"" for e in exchanges)


def log(msg: str) -> None:
    LOG_FILE.parent.mkdir(exist_ok=True)
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def run_iteration(data: dict) -> dict:
    version = data["version"]
    exchanges = data["exchanges"]
    dialogue_str = format_dialogue(exchanges)

    # Step 1: score current dialogue
    score_result = call_ollama(SCORE_PROMPT.format(
        context=CONTEXT,
        version=version,
        dialogue=dialogue_str,
    ))
    score = float(score_result.get("score", 5.0))
    critique = score_result.get("critique", "")
    log(f"v{version} scored {score:.1f}/10 — {critique}")

    # Step 2: rewrite
    rewrite_result = call_ollama(REWRITE_PROMPT.format(
        context=CONTEXT,
        version=version,
        score=f"{score:.1f}",
        dialogue=dialogue_str,
        critique=critique,
    ))
    new_exchanges = rewrite_result.get("exchanges", [])

    if not new_exchanges or not isinstance(new_exchanges, list):
        log("Bad rewrite response, keeping current dialogue.")
        return data

    new_data = copy.deepcopy(data)
    new_data["version"] = version + 1
    new_data["score"] = score
    new_data["score_history"].append({"version": version, "score": score, "critique": critique})
    new_data["exchanges"] = new_exchanges

    log(f"v{version + 1} dialogue ({len(new_exchanges)} exchanges):")
    for e in new_exchanges:
        log(f"  {e['speaker'].upper()}: \"{e['line']}\"")

    return new_data


def main() -> None:
    log(f"Dialogue coach starting — model: {MODEL}")
    log(f"File: {DIALOGUE_FILE}")

    for i in range(MAX_ITERATIONS):
        log(f"\n--- Iteration {i + 1} / {MAX_ITERATIONS} ---")
        try:
            data = load_dialogue()
            new_data = run_iteration(data)

            # Karpathy rule: only save if score improved (or first run)
            if not data["score_history"] or new_data["score"] >= data["score"] - 0.5:
                save_dialogue(new_data)
            else:
                log(f"Score dropped ({new_data['score']:.1f} < {data['score']:.1f}), reverting.")

        except Exception as exc:
            log(f"Error: {exc}")

        time.sleep(RUN_INTERVAL)

    log("Done.")


if __name__ == "__main__":
    main()
