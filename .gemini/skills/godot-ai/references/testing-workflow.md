# AI Testing Workflow

## 1. Visual Verification (Manual)
1. Open the target scene (e.g., `res://level/scenes/BanditAI.tscn`).
2. Press **F6** to run.
3. Observe behavior. Use the **LimboAI Debugger** (if available) to see BT state.
4. Check console for "Activity Logged" messages.

## 2. Headless Research Loop (Automated)
Use this for large-scale verification of behavior changes.

### Run a Cycle
```powershell
.\tools\run_research_cycle.ps1 -episodes 5 -duration 60 -seed 1234
```

### Summarize Results
```bash
python tools/summarize_experiment.py
```

### Evolutionary Tuning
The `EvolutionEngine` will automatically adjust parameters in `evolution_suggestions.json` based on fitness scores. Fitness is role-dependent:
- **Villager**: Survival time + Distance from enemies.
- **Enemy**: Damage dealt + Objective proximity.
- **Companion**: Time spent near villager + Enemy kills.

## 3. Logs & Data
- **Raw Snapshots**: `user://bandit_ai_activity.jsonl`
- **Database**: `logs/bandit_ai_activity.db` (converted via `tools/ai_activity_to_sqlite.py`)
