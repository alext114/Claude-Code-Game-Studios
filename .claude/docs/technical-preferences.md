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

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: [TO BE CONFIGURED — e.g., PC, Console, Mobile, Web]
- **Input Methods**: [TO BE CONFIGURED — e.g., Keyboard/Mouse, Gamepad, Touch, Mixed]
- **Primary Input**: [TO BE CONFIGURED — the dominant input for this game]
- **Gamepad Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Touch Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Platform Notes**: [TO BE CONFIGURED — any platform-specific UX constraints]

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

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: [TO BE CONFIGURED — run /setup-engine]
- **Language/Code Specialist**: [TO BE CONFIGURED]
- **Shader Specialist**: [TO BE CONFIGURED]
- **UI Specialist**: [TO BE CONFIGURED]
- **Additional Specialists**: [TO BE CONFIGURED]
- **Routing Notes**: [TO BE CONFIGURED]

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (primary language) | [TO BE CONFIGURED] |
| Shader / material files | [TO BE CONFIGURED] |
| UI / screen files | [TO BE CONFIGURED] |
| Scene / prefab / level files | [TO BE CONFIGURED] |
| Native extension / plugin files | [TO BE CONFIGURED] |
| General architecture review | Primary |
