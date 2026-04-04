# s&box — Version Reference

| Field | Value |
|-------|-------|
| **Engine** | s&box (Facepunch, Source 2-based) |
| **Engine Version** | [Set by `/setup-engine sbox` — run it to pin the version] |
| **Project Pinned** | [Set by `/setup-engine sbox`] |
| **Last Docs Verified** | [Set by `/setup-engine sbox`] |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | HIGH — s&box API has changed significantly post-cutoff |

---

## Knowledge Gap Warning

The LLM's training data covers an early version of the s&box Component API
(approximately late 2023). The s&box API has undergone major revisions since then.

**Before suggesting any s&box API, you MUST:**
1. Search `site:wiki.facepunch.com/sbox [api-name]` to verify the API exists
2. Check the s&box changelog for breaking changes since late 2023
3. Prefer documented current API over training data

---

## Post-Cutoff Change Summary

> **Run `/setup-engine refresh` to populate this section with real data from**
> **the official s&box changelog via WebSearch.**

| Area | Change Type | Notes |
|------|-------------|-------|
| Component API | Breaking | Class hierarchy and lifecycle methods have evolved |
| Networking | Breaking | `[Sync]`/`[Broadcast]`/`[Authority]` attribute names may have changed |
| Scene system | Breaking | Scene/prefab JSON format has changed |
| Razor UI | Evolving | Panel API and Razor syntax support is active development |
| Physics | Evolving | `Scene.Trace` API may have new overloads |

---

## Verified Sources

- Official wiki: https://wiki.facepunch.com/sbox
- s&box Discord (dev updates): https://discord.gg/sbox
- GitHub (open-source components): https://github.com/Facepunch

---

## Core API — Training Data Baseline

> These are the APIs known at training cutoff (~late 2023). **Verify before use.**

### Component Lifecycle
```csharp
protected override void OnStart() { }        // After all Components created
protected override void OnUpdate() { }       // Per-frame
protected override void OnFixedUpdate() { }  // Fixed timestep (physics)
protected override void OnDestroy() { }      // Cleanup
```

### Multiplayer Attributes
```csharp
IsProxy           // bool property: true if this is a remote instance
[Sync]            // Auto-replicate this property to all clients
[Broadcast]       // Rpc: call on owner, run on ALL clients
[Authority]       // Rpc: call on any client, run only on HOST/SERVER
```

### Physics
```csharp
Scene.Trace.Ray( from, to ).Run()       // Raycast
Scene.Trace.Sphere( r, from, to ).Run() // Sphere cast
CharacterController                      // Character movement Component
```

### Properties
```csharp
[Property]              // Expose to editor
[Property, Range(a, b)] // With range hint
[Property, Group("X")]  // Grouped in editor
```

---

## Sections to Populate (via `/setup-engine refresh`)

Run `/setup-engine sbox [version]` or `/setup-engine refresh` to auto-populate:

- `breaking-changes.md` — API changes from late 2023 to current version
- `deprecated-apis.md` — Old patterns with their replacements
- `current-best-practices.md` — Patterns that have changed since training cutoff
- `modules/networking.md` — Deep-dive on current sync/Rpc API
- `modules/ui.md` — Current Razor panel API
- `modules/physics.md` — Current `Scene.Trace` API
