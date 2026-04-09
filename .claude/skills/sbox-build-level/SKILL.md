---
name: sbox-build-level
description: "Assemble a complete playable level from CSG blocks via direct MCP calls. Guided workflow: gather layout requirements, create floor/wall/ceiling geometry, place structural elements, assign materials, and organize all geometry under a named root container."
argument-hint: "[optional: level name or layout description, e.g., 'Warehouse', 'Arena 2048x2048']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> **Before starting**: Call `get_play_state` via MCP — if the editor is in play mode, call `stop_play_mode` first. CSG changes made during play mode are not saved.
> Builds level geometry using CSG blocks. For complex organic shapes, this generates the structural skeleton — artists finish with hand-modeled assets.

## 1. Parse Arguments

- Extract level name (default: "Level_01")
- Extract optional dimensions hint

---

## 2. Gather Layout Requirements

Ask the user:
1. **Level type** — indoor arena, outdoor zone, corridor network, or open world?
2. **Approximate dimensions** — total playable area (width × depth in units, 1 unit ≈ 1 inch)
3. **Room count** — single room or multiple rooms connected by corridors?
4. **Ceiling height** — standard (256 units), tall (512), or open sky (no ceiling)?
5. **Key features** — cover objects, elevated platforms, doorways, ramps?
6. **Material palette** — concrete, metal, wood, stone, or mixed?
7. **Player count** — affects minimum room dimensions (1-4: small, 5-16: medium, 16+: large)

---

## 3. Create Level Root Container

Call `create_game_object { name: "<LevelName>_Geometry" }` via MCP → rootGUID.
Call `set_game_object_tags { id: rootGUID, add: ["level-geometry", "static"] }` via MCP.

---

## 4. Generate Floor

Calculate floor dimensions from requirements.

Call `create_block` via MCP:
```
{
  name: "Floor_Main",
  parentId: rootGUID,
  x: 0, y: 0, z: 0,
  width: <totalWidth>,
  height: 32,
  depth: <totalDepth>
}
```

Apply floor material via `set_face_material { faceIndex: 0 }` (top face).

---

## 5. Generate Walls

For each wall (4 sides, accounting for doorways):

```
create_block { name: "Wall_North", parentId: rootGUID, x: <x>, y: <height/2>, z: <z>,
               width: <totalWidth>, height: <ceilingHeight>, depth: 32 }
create_block { name: "Wall_South", parentId: rootGUID, ... }
create_block { name: "Wall_East",  parentId: rootGUID, ... }
create_block { name: "Wall_West",  parentId: rootGUID, ... }
```

Apply wall material to visible faces.

---

## 6. Generate Ceiling (if indoor)

```
create_block { name: "Ceiling_Main", parentId: rootGUID,
               x: 0, y: <ceilingHeight>, z: 0,
               width: <totalWidth>, height: 32, depth: <totalDepth> }
```

---

## 7. Generate Interior Features

Based on level type and features requested:

**Cover objects** (every 256–512 units):
```
create_block { name: "Cover_<N>", parentId: rootGUID, x: <x>, y: 48, z: <z>,
               width: 128, height: 96, depth: 32 }
```

**Elevated platforms**:
```
create_block { name: "Platform_<N>", parentId: rootGUID, x: <x>, y: <platformHeight>, z: <z>,
               width: 256, height: 32, depth: 256 }
create_block { name: "Ramp_<N>", parentId: rootGUID, ... }  // connecting ramp
```

**Doorways between rooms**: leave gaps in walls (create two narrower wall segments instead of one wide one).

---

## 8. Apply Materials Consistently

For each block type, apply material from the chosen palette:
- Floor: `materials/dev/floor_concrete.vmat` (or user-specified)
- Walls: `materials/dev/wall_concrete.vmat`
- Cover: `materials/dev/metal_crate.vmat`
- Ceiling: `materials/dev/ceiling_tile.vmat`

Use `set_texture_parameters` to scale UVs to block size (128-unit tiles).

---

## 9. Report Level Summary

Call `get_scene_statistics` via MCP.

Report:
```
✅ Level built: [LevelName]
   Geometry root: [LevelName]_Geometry
   Blocks created: [N]
   Floor area: [W] × [D] units ([W/72] × [D/72] player-widths)
   Rooms: [N]
   Ceiling height: [H] units
   Materials: [list]
```

Next steps:
- `/sbox-vertex-paint` — add vertex color blending to geometry
- `/sbox-setup-navmesh` — configure AI navigation over this level
- `/sbox-spawn-entity` — place player spawns, pickups, and props
- `/sbox-build-ai-encounter` — add enemy encounters

---

## Guardrails

- NEVER create a floor smaller than 512×512 units — below that it's unplayable for most game genres
- Player is ~72 units tall, ~32 units wide — design corridors at minimum 128 units wide, 192 units tall
- Ceiling height should be at least 2× player height (144 units minimum); 256+ for comfortable play
- Leave 128-unit doorway gaps in walls for room connectivity
- Always parent geometry under a named root object — makes the whole level togglable as a group
- Ramps should be ≤45° slope for CharacterController traversal (rise/run ≤ 1:1)
