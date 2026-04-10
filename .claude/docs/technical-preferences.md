# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: s&box (Facepunch, Source 2-based) — date-versioned (~26.04, April 2026)
- **Language**: C# (.NET 10, Component system, hot-reload in editor)
- **Rendering**: Source 2 (same renderer as CS2, Half-Life: Alyx)
- **Physics**: Box3D (modified Rubikon, independent of Valve physics code)
- **Build System**: s&box built-in (`.sbproj`), no standalone CLI compile step
- **Asset Pipeline**: s&box scene/prefab JSON + model compiler

## Naming Conventions

- **Classes/Components**: PascalCase (e.g., `PlayerController`, `FrisbeePhysics`)
- **Public [Property]**: PascalCase (e.g., `MoveSpeed`, `JumpForce`)
- **Private fields**: _camelCase (e.g., `_velocity`, `_lastShoveTime`)
- **Methods**: PascalCase (e.g., `OnUpdate()`, `TakeDamage()`, `StartRagdoll()`)
- **Files**: PascalCase matching class (e.g., `PlayerController.cs`)
- **Scenes/prefabs**: kebab-case filenames (e.g., `losmanos.scene`, `player.prefab`)
- **Constants**: PascalCase or UPPER_SNAKE_CASE

## Performance Budgets

- **Target Framerate**: 60fps (16.6ms frame budget)
- **Tick Rate**: 50Hz (configured in `.sbproj` physics settings)
- **Draw Calls**: [TO BE CONFIGURED]
- **Memory Ceiling**: [TO BE CONFIGURED]

## Testing

- **Framework**: None (no standard s&box test runner — manual in-editor playtesting)
- **Minimum Coverage**: N/A
- **Required Tests**: Playtest each system phase before moving to next (see GDD phases 1–5)

## Forbidden Patterns

- `CharacterController` for player movement — use `PlayerController` + `WishVelocity`
- Coroutines / `yield return` / `async` for gameplay timers — use `TimeSince` / `TimeUntil`
- Re-adding global usings from `Global.cs` (`System`, `Sandbox`, `System.Linq`, etc.)
- Single-line `if`/`else`/`for` bodies without `{ }` braces
- Mutating `[Sync]` state from proxy Components — only owner/host mutates authoritative state
- Polling `Time.Now` for cooldowns — use `TimeSince` / `TimeUntil` structs

## Allowed Libraries / Addons

- s&box built-in APIs only (no NuGet packages for gameplay code)
- `Json.Serialize` / `Json.Deserialize` for serialization (built-in, March 2026+)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
