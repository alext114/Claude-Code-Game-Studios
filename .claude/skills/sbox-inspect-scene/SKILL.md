---
name: sbox-inspect-scene
description: "Deep inspection of a specific GameObject or Component in the active s&box scene via MCP. Reads full component list, all property values, children, tags, and transform. Use for debugging or before modifying an object."
argument-hint: "<ObjectName or GUID> (e.g., 'Player', 'Enemy_01')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.

## 1. Parse Arguments

- Extract object name or GUID
- If not provided: ask "Which object do you want to inspect? (name or GUID)"

---

## 2. Find the Object

If name provided:
Call `find_game_objects { nameContains: "<Name>", maxResults: 10 }` via MCP.

If multiple matches: present list with GUIDs and ask user to confirm the right one.
If GUID provided directly: skip to step 3.

---

## 3. Get Full Object Details

Call `get_game_object_details { id: "<GUID>", includeChildrenRecursive: true }` via MCP.

Capture:
- Name, GUID, enabled state
- World position, rotation, scale
- Tags list
- Parent name (if any)
- All children (names + GUIDs)
- All attached component types

---

## 4. Read All Component Properties

For each component type found in step 3:
Call `get_component_properties { id: "<GUID>", componentType: "<ComponentType>" }` via MCP.

Display each component's properties in a clean table:
```
Component: CharacterController
  Radius:       16
  Height:       64
  StepHeight:   18
  GroundAngle:  45

Component: PlayerController
  MoveSpeed:    200
  JumpStrength: 300
  IsProxy:      false
```

---

## 5. Report Full Summary

```
🔍 Object: [Name]
   GUID: [guid]
   Enabled: [yes/no]
   Tags: [tag list]
   Parent: [parent name or "Scene Root"]
   Position: ([x], [y], [z])
   Rotation: ([pitch], [yaw], [roll])
   Scale: ([x], [y], [z])

   Components ([N] total):
   [component table from step 4]

   Children ([N] total):
   - [child name] (GUID: [guid])
     └─ Components: [list]
```

---

## 6. Optional: Component Filter

If the user only wants to inspect one specific component:
- Ask: "Do you want the full report, or just a specific component? (e.g., 'just NavMeshAgent')"
- Narrow the output accordingly.

---

## 7. Offer Next Steps

```
Inspection complete.

Next steps:
- /sbox-attach-component-mcp [ObjectName] <Component>  — add a component
- /sbox-hotreload-iterate <ComponentName>               — edit the component's C# source
- /sbox-select-frame [ObjectName]                       — focus this object in the editor
- /sbox-generate-prefab [ObjectName]                    — capture this object as a prefab
```

---

## Guardrails

- This skill is READ-ONLY — it never modifies any scene object
- If `get_game_object_details` returns no components, the object may be a plain container — note this in the report
- For large hierarchies (>20 children), summarize child list by count and offer to drill into specific children
- GUID values in the output are valid for follow-up MCP calls in this session
