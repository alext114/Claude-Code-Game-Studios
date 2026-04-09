---
name: sbox-select-frame
description: "Select one or more GameObjects in the s&box editor via MCP and frame the camera on them. Use to focus editor attention on a specific object before configuring it, or to verify scene placement visually."
argument-hint: "<ObjectName or 'tag:tagname'> (e.g., 'Player', 'Enemy_01', 'tag:nav-agent')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> Editor must be in Editor state for selection to be visible.

## 1. Parse Arguments

Argument can be:
- **Object name**: find by name match
- **GUID**: direct selection
- **`tag:<tagname>`**: find all objects with that tag
- **Multiple names**: comma-separated list

If not provided: ask "Which object(s) should I select and frame? (name, GUID, or tag:tagname)"

---

## 2. Find the Target Object(s)

**By name:**
Call `find_game_objects { nameContains: "<Name>", maxResults: 10 }` via MCP.

**By tag:**
Call `find_game_objects { hasTag: "<tagname>", maxResults: 50 }` via MCP.

**By GUID:**
Use directly.

Collect all matching GUIDs into a list.

---

## 3. Select the Objects

Call `set_selected_objects { ids: ["<GUID1>", "<GUID2>", ...] }` via MCP.

Confirm selection was set by checking the return value.

---

## 4. Frame the Selection

Call `frame_selection` via MCP.

This moves the editor viewport camera to focus on the selected objects.

---

## 5. Report

```
✅ Selected and framed: [N] object(s)
   [Name] (GUID: [guid])
   [Name] (GUID: [guid])
   ...

Editor viewport is now focused on these objects.
```

---

## 6. Offer Next Steps

```
Objects are selected in the editor.

Next steps:
- /sbox-inspect-scene [ObjectName]                    — read full component/property details
- /sbox-attach-component-mcp [ObjectName] <Component> — add a component to the selected object
- /sbox-generate-prefab [ObjectName]                  — capture as a prefab
```

---

## Guardrails

- This skill only selects and frames — it does NOT modify any objects
- If no objects match the query, report clearly and suggest `/sbox-scene-context` to browse what's available
- Multiple selection is valid — pass all GUIDs in the `ids` array
- `frame_selection` requires at least one object to be selected first
