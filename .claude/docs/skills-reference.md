# Available Skills (Slash Commands)

68 slash commands organized by phase. Type `/` in Claude Code to access any of them.

## Onboarding & Navigation

| Command | Purpose |
|---------|---------|
| `/start` | First-time onboarding — asks where you are, then guides you to the right workflow |
| `/help` | Context-aware "what do I do next?" — reads current stage and surfaces the required next step |
| `/project-stage-detect` | Full project audit — detect phase, identify existence gaps, recommend next steps |
| `/setup-engine` | Configure engine + version, detect knowledge gaps, populate version-aware reference docs |
| `/adopt` | Brownfield format audit — checks internal structure of existing GDDs/ADRs/stories, produces migration plan |

## Game Design

| Command | Purpose |
|---------|---------|
| `/brainstorm` | Guided ideation using professional studio methods (MDA, SDT, Bartle, verb-first) |
| `/map-systems` | Decompose game concept into systems, map dependencies, prioritize design order |
| `/design-system` | Guided, section-by-section GDD authoring for a single game system |
| `/quick-design` | Lightweight design spec for small changes — tuning, tweaks, minor additions |
| `/review-all-gdds` | Cross-GDD consistency and game design holism review across all design docs |
| `/propagate-design-change` | When a GDD is revised, find affected ADRs and produce an impact report |

## UX & Interface Design

| Command | Purpose |
|---------|---------|
| `/ux-design` | Guided section-by-section UX spec authoring (screen/flow, HUD, or pattern library) |
| `/ux-review` | Validate UX specs for GDD alignment, accessibility, and pattern compliance |

## Architecture

| Command | Purpose |
|---------|---------|
| `/create-architecture` | Guided authoring of the master architecture document |
| `/architecture-decision` | Create an Architecture Decision Record (ADR) |
| `/architecture-review` | Validate all ADRs for completeness, dependency ordering, and GDD coverage |
| `/create-control-manifest` | Generate flat programmer rules sheet from accepted ADRs |

## Stories & Sprints

| Command | Purpose |
|---------|---------|
| `/create-epics` | Translate GDDs + ADRs into epics — one per architectural module |
| `/create-stories` | Break a single epic into implementable story files |
| `/dev-story` | Read a story and implement it — routes to the correct programmer agent |
| `/sprint-plan` | Generate or update a sprint plan; initializes sprint-status.yaml |
| `/sprint-status` | Fast 30-line sprint snapshot (reads sprint-status.yaml) |
| `/story-readiness` | Validate a story is implementation-ready before pickup (READY/NEEDS WORK/BLOCKED) |
| `/story-done` | 8-phase completion review after implementation; updates story file, surfaces next story |
| `/estimate` | Structured effort estimate with complexity, dependencies, and risk breakdown |

## Reviews & Analysis

| Command | Purpose |
|---------|---------|
| `/design-review` | Review a game design document for completeness and consistency |
| `/code-review` | Architectural code review for a file or changeset |
| `/balance-check` | Analyze game balance data, formulas, and config — flag outliers |
| `/asset-audit` | Audit assets for naming conventions, file size budgets, and pipeline compliance |
| `/content-audit` | Audit GDD-specified content counts against implemented content |
| `/scope-check` | Analyze feature or sprint scope against original plan, flag scope creep |
| `/perf-profile` | Structured performance profiling with bottleneck identification |
| `/tech-debt` | Scan, track, prioritize, and report on technical debt |
| `/gate-check` | Validate readiness to advance between development phases (PASS/CONCERNS/FAIL) |
| `/map-systems` | Decompose game concept into systems, map dependencies, prioritize design order, guide per-system GDDs |
| `/design-system` | Guided, section-by-section GDD authoring for a single game system with cross-referencing and incremental writing |
| `/setup-engine` | Configure engine + version, detect knowledge gaps, populate version-aware reference docs |

## s&box MCP Skills

These skills require the s&box MCP server running at `localhost:8098` (s&box editor must be open).

### Scene Intelligence
| Command | Purpose |
|---------|---------|
| `/sbox-scene-context` | Orient to the active scene: counts, hierarchy, component inventory, editor state |
| `/sbox-inspect-scene <Object>` | Deep read of a specific GameObject: all components, properties, children, transform |
| `/sbox-discover-components [keyword]` | Browse TypeLibrary for available component types; probe default property values |
| `/sbox-select-frame <Object>` | Select and frame-camera on a GameObject in the editor viewport |

### Scene Authoring (GameObjects)
| Command | Purpose |
|---------|---------|
| `/sbox-spawn-entity <Name> [at X Y Z]` | Create a named GameObject in the scene with transform and tags |
| `/sbox-attach-component-mcp <Entity> <Type>` | Attach a built-in Component and configure its properties (no C# needed) |
| `/sbox-hotreload-iterate <Component>` | Edit a C# Component, wait for hotload, verify the change is live |

### Prefab Management
| Command | Purpose |
|---------|---------|
| `/sbox-generate-prefab <Entity>` | Capture a scene object as a `.prefab` file |
| `/sbox-prefab-sync [PrefabName]` | Audit and sync prefab instances; apply upstream prefab changes |
| `/sbox-audit-prefab <Name>` | Deep health check: instance sync, missing components, property validation |

### Level Geometry (CSG)
| Command | Purpose |
|---------|---------|
| `/sbox-build-level [Name]` | Guided full level assembly: floors, walls, ceilings, cover, platforms |
| `/sbox-sculpt-block <Name> [WxHxD]` | Create a single CSG block with materials and UV configuration |
| `/sbox-vertex-paint <Block>` | Apply vertex colors and blend weights to CSG geometry |
| `/sbox-hotswap-asset <Asset>` | Force-reload a material/model, or swap an asset reference on a Component |

### AI Navigation
| Command | Purpose |
|---------|---------|
| `/sbox-setup-navmesh` | Create NavMeshArea walkable zones, blockers, and NavMeshLinks |
| `/sbox-spawn-nav-agent <Entity>` | Attach NavMeshAgent to an entity and configure movement parameters |
| `/sbox-build-ai-encounter [Name]` | Full encounter zone: spawn points, nav agents, waypoints, trigger volumes |

### Testing & Validation
| Command | Purpose |
|---------|---------|
| `/sbox-playmode-test [focus]` | Enter play mode, run runtime checks, read editor log, exit play mode |
| `/sbox-setup-multiplayer` | Audit Components for IsProxy guards, [Sync] coverage, RPC correctness |
| `/consistency-check` | Scan all GDDs against the entity registry to detect cross-document inconsistencies (stats, names, rules that contradict each other) |

## QA & Testing

| Command | Purpose |
|---------|---------|
| `/qa-plan` | Generate a QA test plan for a sprint or feature |
| `/smoke-check` | Run critical path smoke test gate before QA hand-off |
| `/soak-test` | Generate a soak test protocol for extended play sessions |
| `/regression-suite` | Map test coverage to GDD critical paths, identify fixed bugs without regression tests |
| `/test-setup` | Scaffold the test framework and CI/CD pipeline for the project's engine |
| `/test-helpers` | Generate engine-specific test helper libraries for the test suite |
| `/test-evidence-review` | Quality review of test files and manual evidence documents |
| `/test-flakiness` | Detect non-deterministic (flaky) tests from CI run logs |
| `/skill-test` | Validate skill files for structural compliance and behavioral correctness |

## Production

| Command | Purpose |
|---------|---------|
| `/milestone-review` | Review milestone progress and generate status report |
| `/retrospective` | Run a structured sprint or milestone retrospective |
| `/bug-report` | Create a structured bug report |
| `/bug-triage` | Read all open bugs, re-evaluate priority vs. severity, assign owner and label |
| `/reverse-document` | Generate design or architecture docs from existing implementation |
| `/playtest-report` | Generate a structured playtest report or analyze existing playtest notes |

## Release

| Command | Purpose |
|---------|---------|
| `/release-checklist` | Generate and validate a pre-release checklist for the current build |
| `/launch-checklist` | Complete launch readiness validation across all departments |
| `/changelog` | Auto-generate changelog from git commits and sprint data |
| `/patch-notes` | Generate player-facing patch notes from git history and internal data |
| `/hotfix` | Emergency fix workflow with audit trail, bypassing normal sprint process |

## Creative & Content

| Command | Purpose |
|---------|---------|
| `/prototype` | Rapid throwaway prototype to validate a mechanic (relaxed standards, isolated worktree) |
| `/onboard` | Generate contextual onboarding document for a new contributor or agent |
| `/localize` | Localization workflow: string extraction, validation, translation readiness |

## Team Orchestration

Coordinate multiple agents on a single feature area:

| Command | Coordinates |
|---------|-------------|
| `/team-combat` | game-designer + gameplay-programmer + ai-programmer + technical-artist + sound-designer + qa-tester |
| `/team-narrative` | narrative-director + writer + world-builder + level-designer |
| `/team-ui` | ux-designer + ui-programmer + art-director + accessibility-specialist |
| `/team-release` | release-manager + qa-lead + devops-engineer + producer |
| `/team-polish` | performance-analyst + technical-artist + sound-designer + qa-tester |
| `/team-audio` | audio-director + sound-designer + technical-artist + gameplay-programmer |
| `/team-level` | level-designer + narrative-director + world-builder + art-director + systems-designer + qa-tester |
| `/team-live-ops` | live-ops-designer + economy-designer + community-manager + analytics-engineer |
| `/team-qa` | qa-lead + qa-tester + gameplay-programmer + producer |
