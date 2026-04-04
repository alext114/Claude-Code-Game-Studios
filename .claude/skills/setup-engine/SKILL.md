---
name: setup-engine
description: "Configure the project's game engine and version. Pins the engine in CLAUDE.md, detects knowledge gaps, and populates engine reference docs via WebSearch when the version is beyond the LLM's training data."
argument-hint: "[engine version] or no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Task
---

When this skill is invoked:

## 1. Parse Arguments

Three modes:

- **Full spec**: `/setup-engine godot 4.6` — engine and version provided
- **Engine only**: `/setup-engine unity` — engine provided, version will be looked up
- **No args**: `/setup-engine` — fully guided mode (engine recommendation + version)

**s&box aliases**: `sbox`, `s&box`, `s-box`, and `sandbox engine` all map to the s&box
setup flow. Example: `/setup-engine sbox` or `/setup-engine s&box 2024`. When detected,
skip the guided mode matrix and jump directly to the s&box setup flow in Step 4.

---

## 2. Guided Mode (No Arguments)

If no engine is specified, run an interactive engine selection process:

### Check for existing game concept
- Read `design/gdd/game-concept.md` if it exists — extract genre, scope, platform
  targets, art style, team size, and any engine recommendation from `/brainstorm`
- If no concept exists, inform the user:
  > "No game concept found. Consider running `/brainstorm` first to discover what
  > you want to build — it will also recommend an engine. Or tell me about your
  > game and I can help you pick."

### If the user wants to pick without a concept, ask:
1. **What kind of game?** (2D, 3D, or both?)
2. **What platforms?** (PC, mobile, console, web?)
3. **Team size and experience?** (solo beginner, solo experienced, small team?)
4. **Any strong language preferences?** (GDScript, C#, C++, visual scripting?)
5. **Budget for engine licensing?** (free only, or commercial licenses OK?)

### Produce a recommendation

Use this decision matrix:

| Factor | Godot 4 | Unity | Unreal Engine 5 | s&box |
|--------|---------|-------|-----------------|-------|
| **Best for** | 2D games, small 3D, solo/small teams | Mobile, mid-scope 3D, cross-platform | AAA 3D, photorealism, large teams | Social/multiplayer 3D, Source-feel, experiments |
| **Language** | GDScript (+ C#, C++ via extensions) | C# | C++ / Blueprint | C# (Component system) |
| **Cost** | Free, MIT license | Free under revenue threshold | Free under revenue threshold, 5% royalty | Free (early access) |
| **Learning curve** | Gentle | Moderate | Steep | Moderate (C# + Source 2 conventions) |
| **2D support** | Excellent (native) | Good (but 3D-first engine) | Possible but not ideal | None (3D only) |
| **3D quality ceiling** | Good (improving rapidly) | Very good | Best-in-class | Good (Source 2) |
| **Web export** | Yes (native) | Yes (limited) | No | No |
| **Console export** | Via third-party | Yes (with license) | Yes | No (PC only) |
| **Open source** | Yes | No | Source available | Partially (via Facepunch) |
| **Multiplayer** | Via Multiplayer API | Via Netcode/Mirror/etc. | Via Unreal Networking | Built-in, first-class |

Present the top 1-2 recommendations with reasoning tied to the user's answers.
Let the user choose — never force a recommendation.

---

## 3. Look Up Current Version

Once the engine is chosen:

- If version was provided, use it
- If no version provided, use WebSearch to find the latest stable release:
  - Search: `"[engine] latest stable version [current year]"`
  - Confirm with the user: "The latest stable [engine] is [version]. Use this?"

---

## 4. Update CLAUDE.md Technology Stack

Read `CLAUDE.md` and update the Technology Stack section. Replace the
`[CHOOSE]` placeholders with the actual values:

**For Godot:**
```markdown
- **Engine**: Godot [version]
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline
```

**For Unity:**
```markdown
- **Engine**: Unity [version]
- **Language**: C#
- **Build System**: Unity Build Pipeline
- **Asset Pipeline**: Unity Asset Import Pipeline + Addressables
```

**For Unreal:**
```markdown
- **Engine**: Unreal Engine [version]
- **Language**: C++ (primary), Blueprint (gameplay prototyping)
- **Build System**: Unreal Build Tool (UBT)
- **Asset Pipeline**: Unreal Content Pipeline
```

**For s&box:**
```markdown
- **Engine**: s&box [version]
- **Language**: C# (Component system)
- **Build System**: s&box built-in (`.sbproj`)
- **Asset Pipeline**: s&box scene/prefab JSON + model compiler
```

### s&box Project Structure

When the engine is s&box, also scaffold the project structure after updating CLAUDE.md.
Ask: "May I create `.sbproj` and the `code/` + `assets/` directory structure?"

**Create `.sbproj`** at the project root:
```json
{
  "Title": "[GameName]",
  "Type": "game",
  "Steamworks": false,
  "Resources": {
    "code/**/*.cs": "code",
    "assets/**": "assets"
  },
  "StartupScene": "assets/scenes/main.scene"
}
```

**Create directory structure** (these directories, not placeholder files):
```
code/
├── Components/
├── Systems/
└── UI/
assets/
├── scenes/
├── prefabs/
├── models/
└── materials/
```

> **Critical**: s&box uses `code/` instead of `src/`. Never create a `src/` directory.
> All game code lives under `code/`. This overrides the default directory-structure.md.

**Create starter component** at `code/Components/PlayerController.cs`:
```csharp
using Sandbox;

/// <summary>
/// Handles player movement and input.
/// Tune values via [Property] attributes in the editor.
/// </summary>
public sealed class PlayerController : Component
{
    [Property] public float MoveSpeed { get; set; } = 200f;
    [Property] public float JumpForce { get; set; } = 300f;

    protected override void OnUpdate()
    {
        if ( IsProxy ) return;
        // Owner-only input handling goes here
    }

    protected override void OnFixedUpdate()
    {
        if ( IsProxy ) return;
        // Physics/movement goes here
    }
}
```

---

## 5. Populate Technical Preferences

After updating CLAUDE.md, create or update `.claude/docs/technical-preferences.md` with
engine-appropriate defaults. Read the existing template first, then fill in:

### Engine & Language Section
- Fill from the engine choice made in step 4

### Naming Conventions (engine defaults)

**For Godot (GDScript):**
- Classes: PascalCase (e.g., `PlayerController`)
- Variables/functions: snake_case (e.g., `move_speed`)
- Signals: snake_case past tense (e.g., `health_changed`)
- Files: snake_case matching class (e.g., `player_controller.gd`)
- Scenes: PascalCase matching root node (e.g., `PlayerController.tscn`)
- Constants: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

**For Unity (C#):**
- Classes: PascalCase (e.g., `PlayerController`)
- Public fields/properties: PascalCase (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_moveSpeed`)
- Methods: PascalCase (e.g., `TakeDamage()`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Constants: PascalCase or UPPER_SNAKE_CASE

**For Unreal (C++):**
- Classes: Prefixed PascalCase (`A` for Actor, `U` for UObject, `F` for struct)
- Variables: PascalCase (e.g., `MoveSpeed`)
- Functions: PascalCase (e.g., `TakeDamage()`)
- Booleans: `b` prefix (e.g., `bIsAlive`)
- Files: Match class without prefix (e.g., `PlayerController.h`)

**For s&box (C#):**
- Classes/Components: PascalCase (e.g., `PlayerController`)
- Public properties: PascalCase with `[Property]` attribute (e.g., `MoveSpeed`)
- Private fields: _camelCase (e.g., `_velocity`)
- Methods: PascalCase (e.g., `OnUpdate()`, `TakeDamage()`)
- Files: PascalCase matching class (e.g., `PlayerController.cs`)
- Scenes/prefabs: kebab-case filenames (e.g., `main-scene.scene`, `player.prefab`)
- Constants: PascalCase or UPPER_SNAKE_CASE

### Remaining Sections
- Performance Budgets: Leave as `[TO BE CONFIGURED]` with a suggestion:
  > "Typical targets: 60fps / 16.6ms frame budget. Want to set these now?"
- Testing: Suggest engine-appropriate framework (GUT for Godot, NUnit for Unity, etc.)
- Forbidden Patterns / Allowed Libraries: Leave as placeholder

### Collaborative Step
Present the filled-in preferences to the user:
> "Here are the default technical preferences for [engine]. Want to customize
> any of these, or shall I save the defaults?"

Wait for approval before writing the file.

---

## 6. Determine Knowledge Gap

Check whether the engine version is likely beyond the LLM's training data.

**Known approximate coverage** (update this as models change):
- LLM knowledge cutoff: **May 2025**
- Godot: training data likely covers up to ~4.3
- Unity: training data likely covers up to ~2023.x / early 6000.x
- Unreal: training data likely covers up to ~5.3 / early 5.4
- s&box: training data covers the early Component API (~late 2023); current API has
  diverged significantly — always treat as `HIGH RISK` regardless of version

Compare the user's chosen version against these baselines:

- **Within training data** → `LOW RISK` — reference docs optional but recommended
- **Near the edge** → `MEDIUM RISK` — reference docs recommended
- **Beyond training data** → `HIGH RISK` — reference docs required

Inform the user which category they're in and why.

---

## 7. Populate Engine Reference Docs

### If WITHIN training data (LOW RISK):

Create a minimal `docs/engine-reference/<engine>/VERSION.md`:

```markdown
# [Engine] — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | [version] |
| **Project Pinned** | [today's date] |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | LOW — version is within LLM training data |

## Note

This engine version is within the LLM's training data. Engine reference
docs are optional but can be added later if agents suggest incorrect APIs.

Run `/setup-engine refresh` to populate full reference docs at any time.
```

Do NOT create breaking-changes.md, deprecated-apis.md, etc. — they would
add context cost with minimal value.

### If BEYOND training data (MEDIUM or HIGH RISK):

Create the full reference doc set by searching the web:

1. **Search for the official migration/upgrade guide**:
   - `"[engine] [old version] to [new version] migration guide"`
   - `"[engine] [version] breaking changes"`
   - `"[engine] [version] changelog"`
   - `"[engine] [version] deprecated API"`

2. **Fetch and extract** from official documentation:
   - Breaking changes between each version from the training cutoff to current
   - Deprecated APIs with replacements
   - New features and best practices

3. **Create the full reference directory**:
   ```
   docs/engine-reference/<engine>/
   ├── VERSION.md              # Version pin + knowledge gap analysis
   ├── breaking-changes.md     # Version-by-version breaking changes
   ├── deprecated-apis.md      # "Don't use X → Use Y" tables
   ├── current-best-practices.md  # New practices since training cutoff
   └── modules/                # Per-subsystem references (create as needed)
   ```

4. **Populate each file** using real data from the web searches, following
   the format established in existing reference docs. Every file must have
   a "Last verified: [date]" header.

5. **For module files**: Only create modules for subsystems where significant
   changes occurred. Don't create empty or minimal module files.

---

## 8. Update CLAUDE.md Import

Update the `@` import under "Engine Version Reference" to point to the
correct engine:

```markdown
## Engine Version Reference

@docs/engine-reference/<engine>/VERSION.md
```

If the previous import pointed to a different engine (e.g., switching from
Godot to Unity), update it.

---

## 9. Update Agent Instructions

For the chosen engine's specialist agents, verify they have a
"Version Awareness" section. If not, add one following the pattern in
the existing Godot specialist agents.

The section should instruct the agent to:
1. Read `docs/engine-reference/<engine>/VERSION.md`
2. Check deprecated APIs before suggesting code
3. Check breaking changes for relevant version transitions
4. Use WebSearch to verify uncertain APIs

### s&box Agent Routing

For s&box projects, assign the following specialist agents:

| Role | Agent | Responsibility |
|------|-------|----------------|
| Lead | `sbox-specialist` | All s&box patterns, project structure, Component architecture |
| Gameplay | `sbox-gameplay-programmer` | Component mechanics, OnUpdate/OnFixedUpdate lifecycle |
| Networking | `sbox-network-programmer` | Built-in multiplayer, `[Sync]`, `[Broadcast]`, `IsProxy` |
| UI | `sbox-ui-programmer` | Razor panels (`.razor`), CSS (`.scss`), `Panel`/`RootPanel` |
| Physics | `sbox-physics-programmer` | `CharacterController`, `Scene.Trace`, physics layers |

All s&box agents read `docs/engine-reference/sbox/VERSION.md` and use WebSearch to
verify any API they cannot confirm from training data.

---

## 10. Refresh Subcommand

If invoked as `/setup-engine refresh`:

1. Read the existing `docs/engine-reference/<engine>/VERSION.md` to get
   the current engine and version
2. Use WebSearch to check for:
   - New engine releases since last verification
   - Updated migration guides
   - Newly deprecated APIs
3. Update all reference docs with new findings
4. Update "Last verified" dates on all modified files
5. Report what changed

---

## 11. Output Summary

After setup is complete, output the engine-appropriate summary:

**For Godot / Unity / Unreal:**
```
Engine Setup Complete
=====================
Engine:          [name] [version]
Knowledge Risk:  [LOW/MEDIUM/HIGH]
Reference Docs:  [created/skipped]
CLAUDE.md:       updated
Tech Prefs:      [created/updated]
Agent Config:    [verified]

Next Steps:
1. Review docs/engine-reference/<engine>/VERSION.md
2. [If from /brainstorm] Run /map-systems to decompose your concept into systems
3. [If from /brainstorm] Run /design-system to author per-system GDDs
4. [If from /brainstorm] Run /prototype [core-mechanic] to test the core loop
5. [If fresh start] Run /brainstorm to discover your game concept
6. Create your first milestone: /sprint-plan new
```

**For s&box:**
```
Engine Setup Complete
=====================
Engine:          s&box [version]
Knowledge Risk:  HIGH (API evolved significantly post-cutoff — always WebSearch)
Project Files:   .sbproj + code/ + assets/ scaffolded
CLAUDE.md:       updated
Tech Prefs:      created
Agent Config:    sbox-specialist assigned

Next Steps:
1. /sbox-create-player-controller — scaffold your player component
2. /sbox-setup-multiplayer       — configure networking conventions
3. /sbox-add-ui-panel            — add your first Razor UI panel
4. /map-systems                  — decompose your concept into systems
5. /sprint-plan new              — plan your first sprint
```

---

## Guardrails

- NEVER guess an engine version — always verify via WebSearch or user confirmation
- NEVER overwrite existing reference docs without asking — append or update
- If reference docs already exist for a different engine, ask before replacing
- Always show the user what you're about to change before making CLAUDE.md edits
- If WebSearch returns ambiguous results, show the user and let them decide
