---
name: sbox-spawn-entity
description: "Create a named GameObject in the active s&box scene via MCP. Sets position, rotation, scale, tags, and optional parent. Returns the GUID for use in follow-up component and property operations."
argument-hint: "<EntityName> [optional: 'at X Y Z'] (e.g., 'Player at 0 64 0', 'EnemySpawn')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.

## 1. Parse Arguments

- Extract entity name from argument (normalize to PascalCase if provided)
- Extract position if `at X Y Z` syntax used
- If no argument provided, ask: "What should this entity be named, and where should it be placed? (e.g., 'Player at 0 64 0')"

---

## 2. Check for Duplicates

Call `find_game_objects { nameContains: "<EntityName>", maxResults: 5 }` via MCP.

If a match is found:
- Report: "A GameObject named `[Name]` already exists (GUID: [id]). Should I (A) use the existing one, (B) create a new one with a different name, or (C) replace it?"
- Wait for user choice.

---

## 3. Ask Configuration Questions

If not all details were provided in the argument, ask:

1. **Position** — where in world space? (x, y, z — default 0, 0, 0; y is up in s&box)
2. **Parent** — should this be parented to another GameObject? (name or "none")
3. **Tags** — any tags to apply? (e.g., "player", "enemy", "spawnable")
4. **Type hint** — is this a: player character, NPC, prop, trigger, spawn point, camera, or other?

The type hint determines which follow-up skills to suggest.

---

## 4. Create the GameObject

Call `create_game_object { name: "<EntityName>", parentId: <GUID or null> }` via MCP.

Capture the returned GUID. Store it in the agent's working memory as `entity_<EntityName>_id`.

---

## 5. Apply Transform

Call `set_game_object_transform` via MCP:
```
{
  id: "<GUID>",
  position: { x: <x>, y: <y>, z: <z> },
  rotation: { pitch: 0, yaw: 0, roll: 0 },
  scale: { x: 1, y: 1, z: 1 }
}
```

---

## 6. Apply Tags

If tags were specified:
Call `set_game_object_tags { id: "<GUID>", add: ["<tag1>", "<tag2>"] }` via MCP.

---

## 7. Verify and Report

Call `get_game_object_details { id: "<GUID>" }` via MCP.

Confirm:
- Name matches
- Position is correct (within 0.01 units)
- Tags are present
- Parent is correct

Report:
```
✅ Entity created: [EntityName]
   GUID: [guid]
   Position: ([x], [y], [z])
   Tags: [tags]
   Parent: [parent name or "Scene Root"]
```

---

## 8. Offer Next Steps

Based on entity type hint:

**Player character:**
```
Next steps:
- /sbox-create-player-controller  — add movement logic
- /sbox-attach-component-mcp      — add components (CharacterController, HealthComponent)
- /sbox-discover-components       — browse available component types
```

**NPC/enemy:**
```
Next steps:
- /sbox-spawn-nav-agent [EntityName]  — add AI navigation
- /sbox-attach-component-mcp          — add health, behavior components
```

**Prop or trigger:**
```
Next steps:
- /sbox-attach-component-mcp  — add collider, rigidbody, or trigger logic
```

---

## Guardrails

- NEVER spawn an entity without confirming the scene is in Editor state (not Playing)
- ALWAYS capture and report the GUID — downstream skills depend on it
- If position is not specified, default to origin (0, 0, 0) and warn the user objects may overlap
- NEVER name entities with spaces — use PascalCase or underscore separators
