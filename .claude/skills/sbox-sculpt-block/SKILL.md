---
name: sbox-sculpt-block
description: "Create and configure a CSG block mesh in the active s&box scene via MCP. Sets dimensions, applies materials to individual faces, and configures texture parameters. The foundation for procedural level geometry."
argument-hint: "<BlockName> [dimensions WxHxD] (e.g., 'Floor 1024x64x1024', 'Wall')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> **Before starting**: Call `get_play_state` via MCP — if the editor is in play mode, call `stop_play_mode` first. CSG changes made during play mode are not saved.
> CSG blocks are solid geometry — s&box automatically computes their collision from the mesh shape.

## 1. Parse Arguments

- Extract block name (PascalCase)
- Extract optional dimensions: Width × Height × Depth in units
- If dimensions not provided: ask "What size should this block be? (e.g., '1024 64 1024' for a floor)"

---

## 2. Ask Configuration Questions

1. **Position** — where in world space? (x, y, z)
2. **Material** — which material to apply? (path to .vmat or "default")
3. **Face-specific materials** — different materials per face? (yes/no)
4. **Purpose** — floor, wall, ceiling, ramp, obstacle, platform? (affects material suggestions)
5. **Parent** — parent to an existing container? (name or "none")

---

## 3. Create the Block

Call `create_block` via MCP:
```
{
  name: "<BlockName>",
  x: <center.x>,
  y: <center.y>,
  z: <center.z>,
  width: <W>,
  height: <H>,
  depth: <D>
}
```

Capture returned GUID.

---

## 4. Apply Material (All Faces)

If a single material for all faces:
Call `set_face_material` via MCP for each face index (0–5 for a box: top, bottom, front, back, left, right):
```
set_face_material { id: "<GUID>", faceIndex: <N>, material: "<path.vmat>" }
```

---

## 5. Apply Face-Specific Materials (if requested)

Ask user for each face:
- Face 0 (top/ceiling): material?
- Face 1 (bottom/floor underside): material?
- Face 2 (front): material?
- Face 3 (back): material?
- Face 4 (left): material?
- Face 5 (right): material?

Apply via `set_face_material` per face.

---

## 6. Configure Texture Parameters (if needed)

Call `set_texture_parameters` via MCP for tiling/scaling:
```
{
  id: "<GUID>",
  faceIndex: <N>,
  scaleX: <tileX>,
  scaleY: <tileY>,
  offsetX: 0,
  offsetY: 0,
  rotation: 0
}
```

For large floors: scale UVs proportionally to block size (1024-unit floor → scaleX: 8, scaleY: 8 for standard 128-unit tile).

---

## 7. Verify the Block

Call `get_mesh_info { id: "<GUID>" }` via MCP.

Confirm: face count, material assignments, vertex count.

Report:
```
✅ CSG Block created: [BlockName]
   GUID: [guid]
   Size: [W] × [H] × [D] units
   Position: ([x], [y], [z])
   Faces: [N]
   Materials: [list per face]
```

---

## 8. Offer Next Steps

```
Block placed in scene.

Next steps:
- /sbox-sculpt-block <AnotherBlock>   — add more geometry
- /sbox-vertex-paint [BlockName]       — paint vertex colors on this block
- /sbox-build-level                    — assemble a full level from blocks
- /sbox-setup-navmesh                  — configure AI navigation over this geometry
```

---

## Guardrails

- NEVER use s&box unit as real-world unit — 1 s&box unit ≈ 1 inch, so a player is ~72 units tall
- Face index 0–5 for a standard block — for complex CSG shapes, use `get_mesh_info` to discover actual face count
- UV scale should match tile size: a 1024-unit surface with a 128-unit texture tile = scaleX/Y of 8
- Large blocks (>4096 units) may cause precision issues — split into multiple blocks
- CSG collision is automatic — no separate collider component needed
