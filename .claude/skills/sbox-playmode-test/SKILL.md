---
name: sbox-playmode-test
description: "Enter s&box play mode via MCP, execute a structured runtime verification checklist, capture results, then return to editor mode. Use after any code or scene change to confirm behavior at runtime."
argument-hint: "[optional: focus area, e.g., 'movement', 'navmesh', 'ui']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> Editor must be in Editor state (not already playing).

## 1. Pre-Play Checks

Call `get_play_state` via MCP.

If already in play mode:
- Report: "Editor is already in play mode. Should I (A) stop and restart, or (B) run checks on current play session?"

Call `get_scene_statistics` via MCP — capture pre-play stats (object count, component count).

---

## 2. Determine Test Focus

If argument provided: focus checks on that system.
If not provided: ask "What should I verify? (e.g., player movement, AI navigation, UI rendering, physics, or run a full checklist)"

---

## 3. Enter Play Mode

Call `start_play_mode` via MCP.

Wait for confirmation that play state is active:
- Poll `get_play_state` up to 3 times with 1-second gaps
- If not active after 3 attempts: report failure and stop

---

## 4. Run System-Specific Checks

### Movement / CharacterController:
```
find_game_objects { hasComponent: "PlayerController" }
get_component_properties { id: "<GUID>", componentType: "CharacterController" }
→ verify: IsOnGround (if accessible), Velocity
```

### NavMesh / AI:
```
find_game_objects { hasComponent: "NavMeshAgent" }
get_component_properties { id: "<GUID>", componentType: "NavMeshAgent" }
→ verify: agent is active, speed non-zero
```

### Physics / Rigidbody:
```
find_game_objects { hasComponent: "Rigidbody" }
get_component_properties { id: "<GUID>", componentType: "Rigidbody" }
→ verify: not sleeping if expected to move
```

### UI Panels:
```
find_game_objects { hasComponent: "PanelComponent" }
→ verify: expected UI objects exist
```

### Custom Components (focus area):
```
find_game_objects { hasComponent: "<FocusComponent>" }
get_component_properties { id: "<GUID>", componentType: "<FocusComponent>" }
→ verify: [Property] values within expected ranges
```

---

## 5. Read Editor Log

Call `get_editor_log { lines: 50 }` via MCP.

Scan for:
- `[Error]` lines — runtime exceptions
- `[Warning]` lines — potential issues
- NullReferenceException, MissingComponent errors
- NavMesh path failures

Categorize: Errors (blocking) / Warnings (review) / Clean.

---

## 6. Stop Play Mode

Call `stop_play_mode` via MCP.

Verify: `get_play_state` confirms return to Editor state.

---

## 7. Report Results

```
✅ Play Mode Test: [PASS / FAIL / WARNINGS]
   Duration: [N] seconds
   Focus: [system tested]

   Checks:
   ✅ PlayerController found and active
   ✅ CharacterController properties accessible
   ⚠️  NavMeshAgent Speed = 0 (possible pathing failure)
   ✅ No runtime errors

   Editor Log:
   Errors: [N]
   Warnings: [N]
   [Paste relevant error lines]

   Issues Found:
   - [Issue]: [suggestion]
```

---

## 8. Offer Next Steps

If errors found:
```
- /sbox-hotreload-iterate <ComponentName>  — fix the error in code
- Read the editor log: get_editor_log { lines: 100 }
```

If clean:
```
- /sbox-hotreload-iterate  — continue iterating on code
- /sbox-generate-prefab    — capture working state as a prefab
- /sbox-setup-multiplayer  — audit for multiplayer correctness
```

---

## Guardrails

- NEVER leave the editor in play mode — always call `stop_play_mode` even if checks fail
- ALWAYS read the editor log — runtime errors may not be visible from property queries alone
- If `start_play_mode` fails, report immediately — do not attempt property reads in editor state
- Play mode resets scene state — any MCP-created objects that are not in the saved scene will not persist
- Do NOT modify scene objects during play mode — changes may be lost on stop
