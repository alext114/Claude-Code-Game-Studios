---
name: sbox-prefab-sync
description: "Audit and synchronize prefab instances in the active s&box scene via MCP. Finds stale instances, applies upstream prefab changes, and detects broken overrides. Use when prefab definitions change and scene instances need updating."
argument-hint: "[optional: prefab name to target, e.g., 'Enemy'] (default: audit all prefabs)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.

## 1. Parse Arguments

- If prefab name provided: target only instances of that prefab
- If not provided: audit all prefab instances in the scene

---

## 2. Discover Prefab Assets

Call `browse_assets { type: "prefab" }` via MCP.

List all `.prefab` files found. Capture their paths.

---

## 3. Find All Prefab Instances

For each prefab (or targeted prefab):
Call `get_prefab_instances { prefabPath: "<path>" }` via MCP.

Collect all instance GUIDs and their parent prefab paths.

Report:
```
Prefab inventory:
  assets/prefabs/Enemy.prefab  →  [N] instances
  assets/prefabs/Player.prefab →  [N] instances
  ...
```

---

## 4. Inspect Each Instance for Staleness

For each instance GUID:
Call `get_game_object_details { id: "<GUID>" }` via MCP.

Check:
- Does the component list match the current prefab definition?
- Are there any broken component references?
- Are there unexpected property overrides (values that differ from prefab defaults)?

Flag instances as:
- **In sync** — matches prefab definition
- **Stale** — component list differs from prefab
- **Override** — has intentional local property overrides (expected)
- **Broken** — missing required components

---

## 5. Apply Upstream Updates (if stale instances found)

For each stale instance:

Present the diff to the user:
```
Instance: Enemy_01 (GUID: abc123)
  Prefab has: [NavMeshAgent, HealthComponent, EnemyBehavior]
  Instance has: [NavMeshAgent, HealthComponent]
  Missing: EnemyBehavior
  → Action: update_from_prefab
```

Ask: "Update this instance from prefab? (A: yes, B: skip, C: update all stale)"

If approved:
Call `update_from_prefab { id: "<instanceGUID>" }` via MCP.

---

## 6. Handle Broken Overrides

If an instance has property overrides that conflict with the updated prefab:

Ask: "Instance [Name] has local overrides that may conflict. Should I (A) keep the overrides (break from prefab), or (B) reset to prefab defaults?"

If break:
Call `break_from_prefab { id: "<instanceGUID>" }` via MCP.
→ Instance becomes independent (no longer tracks prefab).

---

## 7. Verify Final State

Re-run `get_prefab_instances` for updated prefabs and spot-check a sample instance.

Report:
```
✅ Prefab sync complete:
   [N] instances updated from prefab
   [N] instances broken from prefab (now independent)
   [N] instances already in sync (unchanged)
   [N] instances with intentional overrides (kept)
```

---

## 8. Offer Next Steps

```
- /sbox-audit-prefab <Name>       — deep inspection of a specific prefab's health
- /sbox-generate-prefab <Name>    — re-capture a scene object to update the prefab definition
- /sbox-inspect-scene <Instance>  — inspect a specific instance in detail
```

---

## Guardrails

- NEVER call `update_from_prefab` without showing the user a diff first — prefab updates can overwrite intentional scene customizations
- `break_from_prefab` is irreversible within the session (requires manual re-linking) — always confirm first
- Instances with local overrides are NOT stale — they are intentionally customized; only flag component-level mismatches as stale
- After `update_from_prefab`, the instance may need play mode testing to verify behavior hasn't regressed
