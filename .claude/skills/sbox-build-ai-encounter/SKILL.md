---
name: sbox-build-ai-encounter
description: "Design and configure a complete AI enemy encounter zone in the active s&box scene via MCP. Creates spawn points, configures NavMesh agents, sets patrol routes, and establishes trigger volumes for encounter activation."
argument-hint: "[optional: encounter name or zone description, e.g., 'WarehouseAmbush']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> Prerequisites: `/sbox-setup-navmesh` (walkable area) and at least one enemy prefab or entity.

## 1. Parse Arguments

- Extract encounter name (default: "Encounter_01")
- If not provided: ask "What should this encounter be named? (e.g., 'GuardPatrol', 'BossArena', 'AmbushZone')"

---

## 2. Audit Prerequisites

Call `find_game_objects { hasComponent: "NavMeshArea", maxResults: 5 }` via MCP.

If no NavMeshArea: "No NavMesh found. Run `/sbox-setup-navmesh` first."

Call `find_game_objects { hasComponent: "NavMeshAgent", maxResults: 10 }` via MCP.

Report what's already present. Note GUIDs of any existing agents.

---

## 3. Gather Encounter Design

Ask the user:
1. **Enemy count** — how many enemies in this encounter? (1–20)
2. **Enemy type** — which entity/prefab? (name or "create new")
3. **Spawn pattern** — all at once, or staggered? Spawn at start or on trigger?
4. **Activation trigger** — always active, player-enters-zone, or scripted?
5. **Behavior** — patrol fixed routes, chase on sight, defend position, or custom?
6. **Difficulty** — easy/medium/hard (affects speed, reaction time, count)

---

## 4. Create Encounter Root Object

Call `create_game_object { name: "<EncounterName>_Root" }` via MCP → capture rootGUID.

Call `set_game_object_tags { id: rootGUID, add: ["encounter", "ai-zone"] }` via MCP.

---

## 5. Create Spawn Points

For each enemy (count from step 3):

```
create_game_object { name: "SpawnPoint_<N>", parentId: rootGUID }
set_game_object_transform { id: spawnGUID, position: { x: <x>, y: <y>, z: <z> } }
set_game_object_tags { id: spawnGUID, add: ["spawn-point", "enemy-spawn"] }
```

Distribute spawn points across the encounter zone (spread by ~128 units minimum to avoid overlap).

---

## 6. Create or Link Enemy Entities

If enemies already exist in scene: link their GUIDs from step 2.

If creating new: for each enemy spawn point:
```
create_game_object { name: "Enemy_<N>", parentId: rootGUID }
set_game_object_transform { id: enemyGUID, position: <spawnPoint.position> }
create_nav_mesh_agent {
  id: enemyGUID,
  speed: <speed>,          // from difficulty preset in step 9
  acceleration: <accel>,   // from difficulty preset in step 9
  stoppingDistance: <dist>, // from difficulty preset in step 9
  radius: 16
}
set_game_object_tags { id: enemyGUID, add: ["enemy", "nav-agent"] }
```

---

## 7. Create Patrol Waypoints (if patrol behavior)

For patrol encounters, create waypoint chain:
```
create_game_object { name: "Waypoint_A", parentId: rootGUID }
set_game_object_transform { id: waypointA, position: { x: <x1>, y: <y>, z: <z1> } }

create_game_object { name: "Waypoint_B", parentId: rootGUID }
set_game_object_transform { id: waypointB, position: { x: <x2>, y: <y>, z: <z2> } }
```

Note waypoint GUIDs for the user — they'll need to reference these in their patrol C# Component.

---

## 8. Create Activation Trigger (if trigger-based)

First, verify the exact trigger component type name:
```
get_component_types { filter: "Trigger" }
// → find the correct type name (e.g., "TriggerComponent", "BoxTrigger", etc.)
```

Then create the trigger:
```
create_game_object { name: "<EncounterName>_Trigger", parentId: rootGUID }
set_game_object_transform { id: triggerGUID, position: <zone center> }
add_component { id: triggerGUID, componentType: "<verified-trigger-type>" }
set_game_object_tags { id: triggerGUID, add: ["trigger", "encounter-trigger"] }
```

---

## 9. Apply Difficulty Settings

Based on difficulty selected:
- **Easy**: Speed=150, Acceleration=300, StoppingDistance=64
- **Medium**: Speed=200, Acceleration=400, StoppingDistance=48
- **Hard**: Speed=280, Acceleration=600, StoppingDistance=32

Apply via `set_component_property` to all NavMeshAgent components.

---

## 10. Verify Full Encounter

Call `find_game_objects { nameContains: "<EncounterName>", maxResults: 50 }` via MCP.

Report:
```
✅ Encounter configured: [EncounterName]
   Spawn points: [N]
   Enemies: [N] (NavMeshAgent attached)
   Waypoints: [N]
   Trigger zone: [yes/no]
   Difficulty: [easy/medium/hard]
```

---

## 11. Offer Next Steps

```
Encounter scene objects ready. To complete:
- /sbox-create-component EnemyBehavior   — write AI behavior logic (target, attack, patrol)
- /sbox-create-component EncounterManager — write spawn/wave management logic
- /sbox-playmode-test                     — test the encounter at runtime
- /sbox-hotreload-iterate EnemyBehavior  — iterate on AI behavior
```

---

## Guardrails

- NEVER place spawn points outside NavMeshArea bounds — agents will fail to navigate
- Spread spawn points by ≥128 units to prevent spawn overlap artifacts
- The encounter Manager C# Component is the user's responsibility — this skill only creates the scene structure
- For >10 enemies, warn the user about performance and suggest object pooling
- ALWAYS parent all encounter objects under the Root — enables easy enable/disable of the whole encounter
