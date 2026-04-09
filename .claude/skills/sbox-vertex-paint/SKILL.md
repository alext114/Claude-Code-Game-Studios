---
name: sbox-vertex-paint
description: "Apply vertex colors and blend weights to CSG block geometry in the active s&box scene via MCP. Use for terrain-style surface blending, damage decals baked into geometry, or stylistic color variation on level blocks."
argument-hint: "<BlockName or GUID> (e.g., 'Floor_Main', 'Cover_01')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> Target object must be a CSG block created via MCP or the s&box editor.

## 1. Parse Arguments

- Extract block name or GUID
- If not provided: ask "Which block should be vertex painted? (name or GUID)"

---

## 2. Find and Inspect the Block

Call `find_game_objects { nameContains: "<Name>", maxResults: 10 }` via MCP.
Capture GUID.

Call `get_mesh_info { id: "<GUID>" }` via MCP.

Capture:
- Vertex count
- Face count
- Current materials per face

---

## 3. Determine Paint Intent

Ask the user:
1. **Purpose** — surface blend (e.g., concrete + dirt), tint variation, damage marks, or ambient occlusion bake?
2. **Color mode** — uniform color, gradient (top-to-bottom, edge-to-center), or per-face?
3. **Blend mode** — solid color or blend weight for material blending?
4. **Target faces** — all faces, or specific faces? (use face indices from `get_mesh_info`)

---

## 4. Apply Vertex Colors

For solid color or tint:
Call `set_vertex_color` via MCP:
```
{
  id: "<GUID>",
  vertexIndex: <N>,
  r: <0-255>,
  g: <0-255>,
  b: <0-255>,
  a: <0-255>
}
```

For a full block, iterate over all vertices reported by `get_mesh_info`.

**Gradient** (top-to-bottom example):
- Calculate each vertex's Y position relative to block height
- Map Y to color: top = color A, bottom = color B, interpolate

**Per-face**:
- Determine which vertices belong to each face from `get_mesh_info`
- Apply different colors to different face vertex groups

---

## 5. Apply Blend Weights (for material blending)

If using blend mode for material multi-texture blending:
Call `set_vertex_blend` via MCP:
```
{
  id: "<GUID>",
  vertexIndex: <N>,
  blend: <0.0-1.0>
}
```

- 0.0 = 100% primary material
- 1.0 = 100% secondary material
- 0.5 = 50/50 blend

Apply blend gradient: outer edges blend toward secondary material, center stays primary.

---

## 6. Verify Result

Call `get_mesh_info { id: "<GUID>" }` via MCP.

Confirm vertex colors are recorded.

Report:
```
✅ Vertex paint applied: [BlockName]
   Vertices painted: [N]
   Color mode: [uniform/gradient/per-face]
   Blend mode: [solid/blend-weight]
   Range: [color A] → [color B]
```

---

## 7. Offer Next Steps

```
- /sbox-sculpt-block <AnotherBlock>  — paint the next geometry piece
- /sbox-build-level                  — continue level assembly
- /sbox-playmode-test                — preview appearance at runtime
```

---

## Guardrails

- Vertex colors are stored per-vertex, not per-face — large blocks need many vertices for smooth gradients; CSG blocks have limited vertex counts by default
- The visual effect of vertex colors depends entirely on the material's shader — confirm the material supports vertex color blending before painting
- `set_vertex_blend` is only meaningful when the material uses a blend map — check with the technical artist first
- For complex organic blends, vertex painting in the s&box editor by hand is more efficient than MCP — use this skill for programmatic/procedural patterns only
