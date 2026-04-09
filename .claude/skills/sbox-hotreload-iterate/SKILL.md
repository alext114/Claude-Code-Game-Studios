---
name: sbox-hotreload-iterate
description: "Write or edit a C# Component file, wait for s&box's Roslyn hotload to fire, then verify the change is live in the scene via MCP property queries. The core iteration loop for code-driven s&box development."
argument-hint: "<ComponentName> (e.g., 'PlayerController', 'HealthComponent')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`. s&box editor must be open with a scene loaded.
> Hotload fires automatically when any `.cs` file under `code/` is saved — no manual trigger needed.

## 1. Identify the Target Component

- If argument provided: look for `code/Components/<ComponentName>.cs`
- If not provided: ask "Which Component file do you want to edit? (or should I list what's in `code/Components/`?)"

Read the current file content to understand existing structure.

---

## 2. Understand the Desired Change

Ask the user to describe:
1. **What behavior to add/change** — be specific about the logic
2. **Which `[Property]` values, if any** — new tunable parameters
3. **Which lifecycle method** — OnUpdate (input/animation), OnFixedUpdate (physics/movement), OnStart (init), OnDestroy (cleanup)
4. **Multiplayer context** — should the change be owner-only? (`if ( IsProxy ) return`)

---

## 3. Establish Pre-Edit Baseline

Find a live instance of this Component in the scene:
Call `find_game_objects { hasComponent: "<ComponentName>", maxResults: 5 }` via MCP.

If found: call `get_component_properties { id: "<GUID>", componentType: "<ComponentName>" }` via MCP.
Record all current property values as the pre-edit baseline.

If not found: note that post-edit verification will require the user to add the Component to a scene object.

---

## 4. Apply the Edit

Show the proposed code change before writing:
- Show the specific method or property being added/changed
- Highlight any `if ( IsProxy ) return` guards added
- Flag if any `OnUpdate` / `OnFixedUpdate` boundary rules apply

Ask: "May I write this change to `code/Components/<ComponentName>.cs`?"

After approval, write the file using the Edit tool (for targeted changes) or Write (for full rewrites).

---

## 5. Wait for Hotload

After saving, Roslyn compiles in the background. Standard wait: **1–3 seconds**.

Use Bash to pause briefly:
```bash
sleep 2
```

Then probe for hotload success:
Call `get_component_properties { id: "<GUID>", componentType: "<ComponentName>" }` via MCP.

**Success indicator**: any newly added `[Property]` field now appears in the result.
**Failure indicator**: property list unchanged, or `add_component` fails with "type not found".

---

## 6. Handle Hotload Failures

If the component type disappears or properties are missing after edit:

1. Call `get_editor_log { lines: 30 }` via MCP — look for compile errors
2. Report the error to the user with the specific line reference
3. Read the offending line in the source file
4. Propose a fix
5. Ask approval → apply fix → wait → re-verify (loop back to step 5)

Common causes:
- Syntax error in the C# file
- Missing `using Sandbox;` namespace
- Using Unity APIs (`MonoBehaviour`, `Physics.Raycast`, etc.)
- Type not found (missing dependency component)

---

## 7. Verify Behavior via Property Tuning

After hotload succeeds, use MCP to test different property values without touching code:

```
set_component_property { id: "<GUID>", componentType: "<ComponentName>",
  propertyName: "<PropertyName>", value: "<testValue>" }
```

For movement/physics: run `/sbox-playmode-test` to exercise the code at runtime.

---

## 8. Report and Offer Next Steps

```
✅ Hotload successful: [ComponentName]
   New properties live: [list any new [Property] fields]
   Baseline change: [before → after for key values]
   Editor log: [clean / N warnings]

Next steps:
- /sbox-playmode-test         — verify behavior at runtime
- /sbox-setup-multiplayer     — audit IsProxy and [Sync] usage
- /sbox-hotreload-iterate     — continue iteration on next change
```

---

## Guardrails

- NEVER skip the baseline capture — it's the only way to detect hotload failure
- ALWAYS use `OnFixedUpdate` for physics/movement, `OnUpdate` for input
- ALWAYS add `if ( IsProxy ) return` to owner-only methods in multiplayer games
- NEVER use `using UnityEngine;` — use `using Sandbox;`
- NEVER use `Physics.Raycast` — use `Scene.Trace.Ray().Run()`
- If hotload fails 3 times in a row, ask the user to check the s&box editor console directly
