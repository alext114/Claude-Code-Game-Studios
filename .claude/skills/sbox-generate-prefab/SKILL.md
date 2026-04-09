---
name: sbox-generate-prefab
description: "Capture a fully-configured s&box GameObject (with all components and children) from the active scene via MCP, serialize it to a .prefab file, and optionally replace the source with a prefab instance."
argument-hint: "<EntityName> [optional: 'keep-source'] (e.g., 'Player', 'Enemy keep-source')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.

## 1. Parse Arguments

- Extract entity name
- Note if `keep-source` flag is present (default: replace source with prefab instance)
- If no argument: ask "Which GameObject should be serialized into a prefab?"

---

## 2. Find and Inspect the Source Object

Call `find_game_objects { nameContains: "<EntityName>", maxResults: 5 }` via MCP.
Confirm the correct match with the user if multiple found.

Call `get_game_object_details { id: "<GUID>", includeChildrenRecursive: true }` via MCP.

Capture:
- Full component list (name + type for each)
- All children names and their components
- Current world position
- All tags

---

## 3. Check for Existing Prefab

Call `browse_assets { type: "prefab", nameContains: "<EntityName>" }` via MCP.

If a matching prefab already exists:
- Ask: "A prefab named `[Name]` already exists at `[path]`. Should I (A) overwrite it, (B) create as a new variant name, or (C) cancel?"

---

## 4. Determine Prefab Path

Prefab files live in `assets/prefabs/` per s&box conventions.

Ask: "Where should the prefab be saved? (default: `assets/prefabs/[EntityName].prefab`)"

---

## 5. Serialize to Prefab File

Generate prefab JSON from the captured scene state. Write to the chosen path.

The prefab captures:
- All component types present on the root object
- Key `[Property]` values for each component (from `get_component_properties`)
- Child hierarchy and their components
- Tags

Write the file: `assets/prefabs/[EntityName].prefab`

Note to the user:
> "The prefab file contains the structural definition. Some runtime-assigned values (GUID references to other scene objects) may need to be re-linked after instantiation."

---

## 6. Verify Prefab Asset

Call `browse_assets { type: "prefab", nameContains: "<EntityName>" }` via MCP.

Confirm the new prefab appears in the asset browser.

---

## 7. Optional: Replace Source with Prefab Instance

If `keep-source` was NOT specified:

Ask: "Replace the current `[EntityName]` in the scene with a prefab instance? This makes the scene object track the prefab for future syncing."

If yes:
```
1. Note current position from earlier capture
2. destroy_game_object { id: "<sourceGUID>" }
3. instantiate_prefab { path: "assets/prefabs/[EntityName].prefab",
                        x: <pos.x>, y: <pos.y>, z: <pos.z> }
4. get_prefab_instances { prefabPath: "[EntityName].prefab" }
   → Verify 1 instance created
```

---

## 8. Report and Next Steps

```
✅ Prefab created: assets/prefabs/[EntityName].prefab
   Components captured: [list]
   Children: [count]
   [If replaced]: Scene instance linked to prefab.

Next steps:
- /sbox-audit-prefab [EntityName]     — inspect dependencies and instance health
- /sbox-prefab-sync                   — manage instance sync across the scene
- /sbox-spawn-entity                  — instantiate more copies of this prefab
```

---

## Guardrails

- NEVER overwrite an existing prefab without explicit user confirmation
- ALWAYS call `get_component_properties` for each component — do not guess property values
- Prefab files go in `assets/prefabs/` — never in `code/` or `assets/scenes/`
- If the entity has `[Sync]` properties (networked state), note in a comment that these are runtime-only and will initialize to defaults on instantiation
