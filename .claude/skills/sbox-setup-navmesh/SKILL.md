---
name: sbox-setup-navmesh
description: "Configure AI navigation in the active s&box scene via MCP: create NavMeshArea volumes for walkable zones, NavMeshArea blockers for obstacles, and NavMeshLink connections between disconnected regions (stairs, jumps, drops)."
argument-hint: "[optional: 'audit' to check existing nav setup, or room dimensions like '1024 512']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> NavMesh in s&box is built automatically from NavMeshArea volumes — no manual bake step required.

## 1. Audit Existing NavMesh Setup

Call `find_game_objects { hasComponent: "NavMeshArea", maxResults: 50 }` via MCP.
Call `find_game_objects { hasComponent: "NavMeshLink", maxResults: 50 }` via MCP.

If nav objects already exist:
- Report current setup
- Ask: "NavMesh areas already exist. Should I (A) add to the existing setup, (B) audit and fix issues, or (C) replace everything?"

---

## 2. Understand the Level Layout

Ask the user:
1. **Level bounds** — approximate playable area dimensions (width × height × depth in units)
2. **Floors** — single floor or multi-floor? (affects NavMeshLink needs)
3. **Obstacles** — are there large static obstacles (pillars, walls, gaps) that AI must avoid?
4. **Jump links** — are there ledges, stairs, or drops AI should be able to traverse?
5. **Special zones** — lava/damage zones AI should avoid? Off-limits areas?

Alternatively: call `get_scene_summary` and `get_object_bounds` on level geometry objects to infer dimensions automatically.

---

## 3. Create the Walkable Area

For each walkable floor level:

Call `create_nav_mesh_area` via MCP:
```
{
  x: <center.x>,
  y: <center.y>,
  z: <center.z>,
  name: "NavArea_GroundFloor",
  isBlocker: false
}
```

> **Note**: NavMeshArea position/size is configured via its Component properties after creation.
> Use `set_component_property` to adjust the area extent if needed.

---

## 4. Create Blocker Volumes

For each obstacle or restricted zone:

Call `create_nav_mesh_area` via MCP:
```
{
  x: <obstacle.x>,
  y: <obstacle.y>,
  z: <obstacle.z>,
  name: "NavBlocker_<ObstacleName>",
  isBlocker: true
}
```

Common blockers: pits, lava pools, out-of-bounds zones, tall walls.

---

## 5. Create Navigation Links

For each disconnected region agents should traverse (stairs, jumps, drops):

Call `create_nav_mesh_link` via MCP:
```
{
  x: <midpoint.x>,
  y: <midpoint.y>,
  z: <midpoint.z>,
  name: "NavLink_<Description>",
  localStartPosition: { x: 0, y: 0, z: 0 },
  localEndPosition: { x: <dx>, y: <dy>, z: <dz> },
  isBiDirectional: true,
  connectionRadius: 32
}
```

- `isBiDirectional: true` — AI can traverse in both directions (stairs)
- `isBiDirectional: false` — one-way only (ledge drop)
- `connectionRadius` — how close agents must be to use the link (32 units = ~0.5 body widths)

---

## 6. Verify Setup

Call `find_game_objects { hasComponent: "NavMeshArea" }` via MCP → count areas and blockers.
Call `find_game_objects { hasComponent: "NavMeshLink" }` via MCP → count links.

Report:
```
✅ NavMesh configured:
   Walkable areas: [N]
   Blockers: [N]
   Nav links: [N]
   Coverage: [described from user-provided dimensions]
```

---

## 7. Tag Navigation Objects

Call `set_game_object_tags` for all nav objects:
- NavMeshArea (walkable): `add: ["navmesh", "walkable"]`
- NavMeshArea (blocker): `add: ["navmesh", "blocker"]`
- NavMeshLink: `add: ["navmesh", "link"]`

This allows efficient querying later: `find_game_objects { hasTag: "navmesh" }`.

---

## 8. Offer Next Steps

```
NavMesh ready for AI agents.

Next steps:
- /sbox-spawn-nav-agent <NPCName>  — create an AI agent that uses this nav mesh
- /sbox-build-ai-encounter         — set up a complete enemy encounter zone
- /sbox-playmode-test              — verify agents navigate correctly at runtime
```

---

## Guardrails

- NavMeshArea volumes must overlap with walkable geometry — a floating area with no ground beneath it will produce no valid nav data
- `connectionRadius` on NavMeshLink must be at least as large as the agent radius (typically 16 units) or agents cannot reach the link
- NEVER create nav links between areas with no logical traversal path — AI will attempt physically impossible moves
- If multi-floor: every floor needs its own NavMeshArea; links connect floors
