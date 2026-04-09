---
name: sbox-spawn-nav-agent
description: "Create an AI navigation agent on a GameObject in the active s&box scene via MCP. Attaches NavMeshAgent component, configures movement parameters, and wires it to the existing NavMesh. Prerequisite: /sbox-setup-navmesh must be complete."
argument-hint: "<EntityName> (e.g., 'Enemy', 'Patrol_Guard')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> NavMesh must already exist in the scene — run `/sbox-setup-navmesh` first.

## 1. Parse Arguments

- Extract entity name from argument
- If not provided: ask "Which entity should become a NavMesh agent? (run `/sbox-spawn-entity` first if the entity doesn't exist yet)"

---

## 2. Verify NavMesh Exists

Call `find_game_objects { hasComponent: "NavMeshArea", maxResults: 5 }` via MCP.

If no NavMeshArea found:
- Report: "No NavMesh found in scene. Run `/sbox-setup-navmesh` first to create walkable areas."
- Stop.

---

## 3. Find the Target Entity

Call `find_game_objects { nameContains: "<EntityName>", maxResults: 10 }` via MCP.

If not found: "No GameObject named `[Name]` found. Run `/sbox-spawn-entity [Name]` first."
Capture entity GUID.

---

## 4. Ask Agent Configuration Questions

1. **Movement speed** — how fast does this agent move? (default: 200 units/sec)
2. **Acceleration** — how quickly does it reach top speed? (default: 400)
3. **Stopping distance** — how close does it get to its target before stopping? (default: 32 units)
4. **Agent radius** — collision radius for pathfinding (default: 16 units — must match NavMeshLink connectionRadius)
5. **Purpose** — patrol, chase player, flee, or custom behavior?

---

## 5. Check for Existing NavMeshAgent

Call `get_game_object_details { id: "<GUID>" }` via MCP.

If NavMeshAgent already attached:
- Report: "`NavMeshAgent` already attached. Should I (A) reconfigure it, or (B) skip?"

---

## 6. Probe NavMeshAgent Properties

```
1. create_game_object { name: "__NavAgentProbe__" }  → probeGUID
2. add_component { id: probeGUID, componentType: "NavMeshAgent" }
3. get_component_properties { id: probeGUID, componentType: "NavMeshAgent" }
   → capture: Speed, Acceleration, StoppingDistance, Radius, etc.
4. destroy_game_object { id: probeGUID }
```

---

## 7. Attach and Configure NavMeshAgent

Use the dedicated NavMeshAgent tool (includes all properties in one call):
```
create_nav_mesh_agent {
  id: "<GUID>",
  speed: <speed>,
  acceleration: <acceleration>,
  stoppingDistance: <stoppingDistance>,
  radius: <radius>
}
```

---

## 8. Tag the Agent

Call `set_game_object_tags { id: "<GUID>", add: ["npc", "nav-agent"] }` via MCP.

---

## 9. Verify Final State

Call `get_component_properties { id: "<GUID>", componentType: "NavMeshAgent" }` via MCP.

Report:
```
✅ NavMesh agent configured: [EntityName]
   Speed: [value]
   Acceleration: [value]
   StoppingDistance: [value]
   Radius: [value]
   NavMesh areas found: [N]
```

---

## 10. Offer Next Steps

Based on agent purpose:

**Chase / Combat AI:**
```
Next steps:
- /sbox-build-ai-encounter  — configure enemy encounter zone with this agent
- /sbox-create-component    — write AI behavior logic (target selection, attack range)
- /sbox-playmode-test       — verify navigation at runtime
```

**Patrol:**
```
Next steps:
- /sbox-spawn-entity PatrolPoint_A  — create patrol waypoints
- /sbox-create-component PatrolController  — write waypoint traversal logic
- /sbox-playmode-test               — verify patrol route
```

---

## Guardrails

- NEVER create a NavMeshAgent with Radius smaller than the NavMeshLink connectionRadius — agent cannot reach links
- ALWAYS verify a NavMeshArea exists before attaching the agent — otherwise the agent has nothing to navigate
- If the entity has no collider, remind the user to add one or the agent will clip through geometry
- The NavMeshAgent only handles pathfinding — behavior logic (attack, patrol, flee) requires a custom C# Component via `/sbox-create-component`
