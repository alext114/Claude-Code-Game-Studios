---
name: sbox-hotswap-asset
description: "Reload or swap an asset in the active s&box scene via MCP without restarting. Forces a material, model, or texture to reload from disk, or replaces an asset reference on a Component with a different asset. Use for rapid art iteration."
argument-hint: "<AssetPath or ObjectName> (e.g., 'materials/dev/floor.vmat', 'Enemy')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> Hot-swapping assets does not require editor restart — changes are visible immediately.

## 1. Parse Arguments

- If asset path (contains `/` or `.vmat`/`.vmdl`/`.vtex`): reload/swap that specific asset
- If object name: find the object and offer to swap assets on its components
- If not provided: ask "What do you want to hot-swap? (asset path, or object name to swap its model/material)"

---

## 2. Determine Operation Type

Ask if not clear from argument:
1. **Reload** — force an existing asset to reload from disk (after you've modified the file externally)
2. **Swap** — replace an asset reference on a Component with a different asset path

---

## 3A. Reload Asset

If reloading:

Call `reload_asset { path: "<assetPath>" }` via MCP.

Verify: the asset manager reports a reload event in the editor log.
Call `get_editor_log { lines: 10 }` via MCP → look for reload confirmation.

Report:
```
✅ Asset reloaded: [path]
   Changes visible in scene immediately.
```

---

## 3B. Swap Asset on a Component

If swapping:

Find the object: `find_game_objects { nameContains: "<ObjectName>" }` → GUID.

Get current asset references:
`get_component_properties { id: "<GUID>", componentType: "<ComponentType>" }` → find model/material property.

Ask: "Current asset: `[currentPath]`. What should it be replaced with? (new asset path)"

Search for the new asset:
`search_assets { query: "<keyword>", type: "<material|model>" }` via MCP.

Present matches and confirm selection.

Apply:
`set_component_property { id: "<GUID>", componentType: "<ComponentType>",
  propertyName: "<AssetPropertyName>", value: "<newAssetPath>" }` via MCP.

---

## 4. Verify the Swap

Call `get_component_properties { id: "<GUID>", componentType: "<ComponentType>" }` via MCP.

Confirm the property now shows the new asset path.

Report:
```
✅ Asset swapped: [ObjectName]
   Property: [PropertyName]
   Before: [oldPath]
   After:  [newPath]
```

---

## 5. Offer Next Steps

```
- /sbox-playmode-test              — verify the asset looks correct at runtime
- /sbox-hotswap-asset <Another>    — swap another asset
- /sbox-generate-prefab <Object>   — capture the updated state as a prefab
```

---

## Guardrails

- `reload_asset` only works for assets the s&box editor already knows about — newly created files may need the editor asset browser refreshed first
- NEVER swap a model asset on a Component without checking that the new model has compatible skeletons if animations are involved
- Asset paths are relative to the project root (e.g., `assets/models/enemy.vmdl`) — absolute paths will not work
- Hot-swapping materials during play mode is supported but changes will be lost when play mode stops if the scene hasn't been saved
- Use `search_assets` to discover valid asset paths — do NOT guess asset paths
