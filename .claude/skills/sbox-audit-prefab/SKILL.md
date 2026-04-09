---
name: sbox-audit-prefab
description: "Deep health check on a specific s&box prefab: verifies all instances are in sync, checks for missing components, validates component property ranges, and reports the prefab's dependency tree."
argument-hint: "<PrefabName> (e.g., 'Enemy', 'Player')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.

## 1. Parse Arguments

- Extract prefab name
- If not provided: ask "Which prefab should be audited? (e.g., 'Enemy', or 'all' for a full scene prefab audit)"

---

## 2. Find the Prefab Asset

Call `browse_assets { type: "prefab", nameContains: "<Name>" }` via MCP.

If not found: "No prefab named `[Name]` found. Use `/sbox-generate-prefab` to create one."

Capture prefab path.

---

## 3. Read Prefab Structure

Call `get_prefab_structure { path: "<prefabPath>" }` via MCP.

Capture:
- Root component list
- Child hierarchy
- All component types defined in the prefab

---

## 4. Find All Instances

Call `get_prefab_instances { prefabPath: "<path>" }` via MCP.

Count and list all instance GUIDs.

---

## 5. Audit Each Instance

For each instance GUID (sample up to 10; report if more exist):
Call `get_game_object_details { id: "<GUID>", includeChildrenRecursive: true }` via MCP.

Check:
- **Component completeness**: does the instance have all components defined in the prefab?
- **Missing components**: list any components present in prefab but absent from instance
- **Extra components**: list any components on instance not in prefab (local additions)
- **Broken references**: any component referencing a GUID that no longer exists?

---

## 6. Validate Property Ranges

For each instance's custom C# components:
Call `get_component_properties { id: "<GUID>", componentType: "<Type>" }` via MCP.

Flag values that look wrong:
- Speed = 0 (likely forgotten to set)
- Health ≤ 0
- Any float = NaN or Infinity
- Any string = null or empty when it shouldn't be

---

## 7. Check Prefab File vs Source Code

Use Glob to find the C# Component files referenced by this prefab:
```
Glob: code/Components/<ComponentName>.cs
```

For each C# Component:
- Verify the file exists
- Verify the class name matches the component type name
- Check for obvious issues: missing `using Sandbox;`, class not extending `Component`

---

## 8. Generate Audit Report

```
🔍 Prefab Audit: [PrefabName]
   Path: [path]
   Instances found: [N]

   Prefab definition:
   ✅ Components: [list]
   ✅ Children: [N]

   Instance health ([N] checked):
   ✅ [N] instances fully in sync
   ⚠️  [N] instances missing components: [list]
   ❌ [N] instances broken (missing required components)

   Property issues:
   ⚠️  [Instance GUID]: Speed = 0 (likely needs to be set)
   ⚠️  [Instance GUID]: HealthMax = 0

   Source code:
   ✅ EnemyBehavior.cs — found, valid
   ⚠️  PatrolController.cs — NOT FOUND (component will fail to compile)

   Overall: [HEALTHY / NEEDS ATTENTION / BROKEN]
```

---

## 9. Offer Remediation

Based on findings:
```
Recommended actions:
- /sbox-prefab-sync [PrefabName]     — update stale instances
- /sbox-create-component PatrolController — recreate missing source file
- /sbox-inspect-scene [InstanceName] — inspect a specific broken instance
```

---

## Guardrails

- NEVER modify any prefab or instance during this audit — this is read-only
- If >10 instances, sample 10 and note the total count — auditing all is prohibitively slow
- A missing source file does not mean the component is broken at runtime — it may have been removed intentionally; always ask before flagging as critical
