---
name: sbox-scene-context
description: "Orient to the active s&box scene via MCP: query object counts, hierarchy, existing components, and editor state. Use this before any build task to establish a baseline and avoid duplicating existing work."
argument-hint: "[optional: 'full' for deep hierarchy scan, default is summary only]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`. If unavailable, report and stop.

## 1. Verify MCP Availability

Call `get_editor_context` via MCP.

If the call fails or returns "No active scene":
- Report: "MCP server is unreachable or no scene is open. Start s&box editor and open a scene first."
- Stop.

If successful, note:
- Active scene name
- Current play state (Editor / Playing / Paused)
- Any currently selected objects

---

## 2. Scene Summary

Call `get_scene_summary` via MCP.

Record and report:
- Total object count (root / enabled / disabled)
- All unique tags present
- Top component types by frequency
- Number of prefab instances
- Network mode distribution (if multiplayer)

---

## 3. Hierarchy Scan

If argument is `full` or user requests deeper scan:
- Call `get_scene_hierarchy { rootOnly: true }` → top-level structure
- For any root object with children, call `get_scene_hierarchy { rootId: "<GUID>" }` → expand subtree

If default (no argument):
- Call `get_scene_hierarchy { rootOnly: true }` only

---

## 4. Report and Recommend

Present a structured scene brief:

```
Scene: [scene name]  |  State: [Editor/Playing]
─────────────────────────────────────────────
Objects: [total] total  ([root] root, [enabled] enabled, [disabled] disabled)
Tags: [list]
Top components: [ComponentName: count, ...]
Prefabs: [N instances from M sources]

Hierarchy:
  [Root objects tree]

⚠️  Notes:
  - [Any disabled orphan objects found]
  - [Any suspicious component counts]
  - [Missing essential objects, e.g., no Camera found]
```

If the scene is empty (0 objects or only default lights):
- Suggest: "Scene appears empty. Run `/sbox-build-level` to create geometry or `/sbox-spawn-entity` to add entities."

---

## 5. Session State Update

After the scan, update `production/session-state/active.md` with:
- Scene name
- Baseline object count
- Key entity GUIDs found (player, camera, etc.) if identifiable by name or tag

---

## Guardrails

- NEVER modify anything in this skill — it is read-only orientation
- If scene has >200 objects, warn the user before running a full hierarchy scan
- Always check for `mcp_ignore`-tagged objects and exclude them from reports
- If play state is "Playing", note that scene queries reflect runtime state, not editor state
