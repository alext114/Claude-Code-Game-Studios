# Codex Port Plan

Porting Claude Code Game Studios to OpenAI Codex CLI, with continued Claude Code support.

| Field | Value |
|-------|-------|
| **Status** | Draft — awaiting approval |
| **Author** | Claude Code session |
| **Date** | 2026-09-12 |
| **Port shape** | Dual-support, single repo |
| **Verification basis** | `openai/codex` @ `b979d4f` (source-read, not docs-read) |
| **Estimated effort** | 8–10 days |

---

## 1. Summary

Codex CLI has converged substantially on Claude Code's extension model. It now
supports repo-scoped **skills** (`SKILL.md`), **custom agent roles**, and a
**lifecycle hooks system** whose event names, stdin schema, and exit-code
semantics are deliberately Claude-Code-compatible — it accepts `Bash`, `Write`,
`Edit`, and `Agent` as hook matcher aliases explicitly for this purpose.

The consequence: **the prose ports nearly free.** All 902 KB of skill bodies and
446 KB of agent bodies carry over. What needs work is the thin structural layer
where Claude Code frontmatter encodes behaviour that Codex expresses elsewhere —
and that layer is a *closed, enumerable* set of mappings, which makes it
scriptable rather than editorial.

This plan therefore centres on a **generator**: `.claude/` remains the single
source of truth, written in Claude idiom, and a sync script emits `.codex/`.

### What this port does not do

- It does not rewrite skill or agent content to be "engine-neutral."
- It does not move or rename any file under `.claude/`.
- It does not change the studio workflow, the agent roster, or the phase gates.

---

## 2. Inventory

| Asset | Count | Size |
|---|---:|---:|
| Skills (`.claude/skills/*/SKILL.md`) | 94 | 902 KB |
| Agents (`.claude/agents/*.md`) | 57 | 446 KB |
| Hook scripts (`.claude/hooks/*.sh`) | 13 | 32 KB |
| Path rules (`.claude/rules/*.md`) | 12 | 17 KB |
| Docs + templates (`.claude/docs/**`) | 61 | — |
| MCP servers (`.mcp.json`) | 2 | — |
| Root instructions (`CLAUDE.md` + 6 `@imports`) | 7 files | 20 KB flattened |
| Status line (`.claude/statusline.sh`) | 1 | — |

Cross-reference density inside bodies (this is the rewrite surface):

| Pattern | Files | Occurrences |
|---|---:|---:|
| `/skill-name` references | — | 991 |
| `AskUserQuestion` | 78 | 265 |
| `Task` | 75 | — |
| `TodoWrite` | 35 | 35 |
| `WebSearch` | 20 | 37 |
| `Write`/`Edit` | 47 | 47 |

---

## 3. Decisions taken

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Port shape | **Dual-support, one repo** | Both tools usable on the same game project; generator eliminates double-maintenance |
| D2 | Model tiering | **Map tiers onto reasoning effort** | Preserves the cost/quality discipline in `coordination-rules.md` |
| D3 | Source of truth | **`.claude/` canonical** | Avoids moving 151 files and breaking 86 in-body `.claude/docs/` path references |
| D4 | Generated output | **Committed to the repo** | A Codex user cloning the repo works immediately, with no build step |
| D5 | Copy vs. symlink | **Copy** | Codex *does* follow directory symlinks for repo-scoped skills, but s&box development is Windows, where Git checks symlinks out as plain text unless `core.symlinks=true` |

---

## 4. Compatibility matrix

Verified by reading Codex source, with file references.

| Claude Code | Codex target | Verdict | Source reference |
|---|---|---|---|
| `.claude/skills/*/SKILL.md` | `.codex/skills/*/SKILL.md` | **Loads unchanged** — unknown frontmatter keys ignored, not rejected | `skills/src/parser.rs` (no `deny_unknown_fields`) |
| `.claude/agents/*.md` | `.codex/agents/*.toml` | Mechanical conversion | `agent-roles/src/agent_role_config.rs` |
| `settings.json` → `hooks` | `.codex/hooks.json` | Near-identical schema | `config/src/hook_config.rs` |
| `.mcp.json` | `[mcp_servers.*]` in `.codex/config.toml` | Trivial | `config/src/mcp_types.rs` |
| `CLAUDE.md` + `@imports` | `AGENTS.md` (flattened) | **No `@import` support**; 32 KiB cap | `core/src/agents_md.rs` |
| `.claude/rules/*.md` | unchanged, referenced by path | Free — they are prose, not mechanically enforced | — |
| `.claude/docs/**` | unchanged | Free | — |
| `.claude/statusline.sh` | — | **No equivalent. Drop.** | — |

### Skill discovery roots (Codex)

- `<project>/.codex/skills/` → scope `Repo`
- `<dir>/.agents/skills/` for each dir between project root and cwd → scope `Repo`
- `$CODEX_HOME/skills/` (deprecated), `~/.agents/skills/` → scope `User`

We target `.codex/skills/`.

### Agent role discovery (Codex)

`<config_folder>/agents/**/*.toml`, recursively. For us: `.codex/agents/*.toml`.

---

## 5. Architecture: the generator

```
.claude/                      ← SOURCE OF TRUTH (Claude idiom, hand-edited)
├── skills/*/SKILL.md
├── agents/*.md
├── hooks/*.sh
├── rules/*.md
├── docs/**
└── settings.json

tools/codex-sync/
├── sync.py                   ← the generator
├── mappings.toml             ← tool table, tier map, sandbox overrides
└── README.md

.codex/                       ← GENERATED (committed, never hand-edited)
├── config.toml
├── hooks.json
├── skills/*/SKILL.md
└── agents/*.toml

AGENTS.md                     ← GENERATED (flattened CLAUDE.md chain)
```

Every generated file carries a header comment:

```
<!-- GENERATED by tools/codex-sync — do not edit. Source: .claude/skills/foo/SKILL.md -->
```

### Drift guard

A CI job runs the generator and fails if `git diff --exit-code` is non-empty.
This is the mechanism that makes dual-support sustainable: it is impossible to
land a `.claude/` change without the matching `.codex/` regeneration.

---

## 6. Mapping reference

### 6.1 Skill frontmatter

Codex reads exactly three fields: `name`, `description`, `metadata.short-description`.

| Claude key | Present on | Codex handling |
|---|---:|---|
| `name` | 94 | **Kept** |
| `description` | 94 | **Kept** |
| `argument-hint` | 94 | Dropped by Codex → **fold into `description`** so args stay discoverable |
| `user-invocable` | 94 | Dropped — all Codex skills are invocable via `$name` |
| `allowed-tools` | 94 | **No equivalent.** See §6.4 |
| `model` | 11 | **No equivalent.** See §6.5 |
| `agent` | 19 | **No equivalent.** Generator injects explicit delegation line — see §6.3 |
| `context` | 4 | Dropped |
| `isolation: worktree` | 1 (`prototype`) | **No equivalent.** Becomes a manual `git worktree` step in the body |

### 6.2 Agent frontmatter → TOML

```toml
# .codex/agents/producer.toml
name        = "producer"
description = "The Producer manages all production concerns..."
model       = "<pin at port time>"
model_reasoning_effort = "high"

developer_instructions = """
You are the Producer for an indie game project.
...
"""
```

**Both `name` and `description` and `developer_instructions` are required.**
Directory-discovered roles pass `role_name_hint: None`
(`agent-roles/src/loader.rs:303`), which makes `developer_instructions`
mandatory — a role file missing it fails to load with a startup warning rather
than an error, so it will fail *silently*. The generator must assert on this.

| Claude key | Present on | Codex handling |
|---|---:|---|
| `name` | 57 | `name` |
| `description` | 57 | `description` |
| body prose | 57 | `developer_instructions` (multiline TOML string) |
| `model` | 57 | `model` + `model_reasoning_effort` — see §6.5 |
| `tools` | 57 | **Largely no equivalent.** See §6.4 |
| `disallowedTools: Bash` | 15 | **No clean equivalent.** See §6.4 |
| `maxTurns` | 57 | No equivalent — drop |
| `memory: user` | 17 | No equivalent — drop |
| `skills: [...]` | 6 | No equivalent — mention the skills in `developer_instructions` |
| `isolation: worktree` | 1 (`prototyper`) | No equivalent — manual worktree step |

### 6.3 Tool vocabulary (in-body rewrites)

| Claude Code | Codex | Notes |
|---|---|---|
| `Task` | `spawn_agent` | Codex **does not auto-spawn custom roles**; delegation must be explicit |
| `AskUserQuestion` | `request_user_input` | Gated behind `tools.experimental_request_user_input` |
| `TodoWrite` | `update_plan` | Gated behind `tools.update_plan` |
| `WebSearch` | `web_search` | Gated behind `tools.web_search` |
| `Write` / `Edit` | `apply_patch` | |
| `Read` | `read_file` / shell | |
| `Bash` | `shell` | |
| `Glob` / `Grep` | shell (`rg`, `find`) | 226 and 199 occurrences — mostly incidental prose |
| `/skill-name` | `$skill-name` | 991 occurrences; safe because the 94-name list is closed |

**Refined in Phase 0 — two rewrite classes, not one.** The table above is not
safely applied uniformly. `Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep` and
`Task` are ordinary English words: rewriting them bare turns "Read the story
file" into "read_file the story file". The generator therefore splits them:

- **Safe** (`AskUserQuestion`, `TodoWrite`, `WebSearch`, `WebFetch`,
  `SlashCommand`) — CamelCase, not English words. Rewritten anywhere.
- **Contextual** (the rest) — rewritten **only** inside backticks (`` `Read` ``)
  or in an explicit `"Read tool"` phrasing. Everything else is left for human
  review.

Three of these are **config-gated** and must be enabled in `.codex/config.toml`,
or 78 skills will instruct the model to use a tool that does not exist:

```toml
[tools]
web_search = true
update_plan = { enabled = true }
experimental_request_user_input = { enabled = true }
```

For the 19 skills carrying an `agent:` field, the generator injects an explicit
delegation instruction near the top of the body, because Codex will not route
automatically:

> Delegate this work to the `technical-director` agent role via `spawn_agent`.

### 6.4 Tool restriction — the honest gap

Codex's `ToolsToml` exposes only `web_search`, `update_plan`, and
`experimental_request_user_input`. There is **no per-skill or per-agent tool
allowlist**. The `allowed-tools` field on all 94 skills and the `tools:` field
on all 57 agents have no direct target.

The material loss is the 15 agents carrying `disallowedTools: Bash`:

> art-director, audio-director, community-manager, creative-director,
> economy-designer, game-designer, level-designer, live-ops-designer,
> narrative-director, sound-designer, systems-designer, ue-blueprint-specialist,
> ux-designer, world-builder, writer

These are design and narrative roles that may write files but must not run shell
commands. Codex's `sandbox_mode` has three values — `read-only`,
`workspace-write`, `danger-full-access` — and **none of them expresses "may write
files, may not run shell."** `read-only` would also block `apply_patch`, which
these roles need.

**Recommended solution:** a `PreToolUse` hook matched on `Bash`, keyed on the
`agent_type` field that Codex includes in hook stdin, exiting 2 to block.

```
.codex/hooks.json → PreToolUse, matcher "Bash" → .codex/hooks/deny-shell-for-roles.sh
```

**Deviation from this plan, taken in Phase 3.** The script was originally
specified at `.claude/hooks/deny-shell-for-roles.sh`. It is generated into
`.codex/hooks/` instead: it is a generated artefact, and generated artefacts
belong under `.codex/`, not in the hand-edited source tree. It is also
Codex-only — Claude Code enforces this natively and does not want the hook.

The hook reads `agent_type` from stdin, checks it against the 15-name list, and
exits 2 with a reason. This reproduces the Claude Code behaviour faithfully and
is generated from the same frontmatter, so it stays in sync automatically. It is
new code — budget it in Phase 3.

### 6.5 Model tiers → reasoning effort (D2)

Codex's ladder: `none | minimal | low | medium | high | xhigh | max | ultra`.

| Claude tier | Codex effort | Applies to |
|---|---|---|
| `haiku` | `low` | Read-only status checks, formatting, lookups |
| `sonnet` | `medium` | Default — implementation, design authoring |
| `opus` | `high` | Multi-document synthesis, cross-system review |
| `opus` (gates) | `xhigh` | `/gate-check`, `/review-all-gdds`, `/architecture-review` |

**Agents** (tier rides on the role — clean):

- `high`: creative-director, producer, technical-director
- `low`: community-manager, devops-engineer, sound-designer
- `medium`: the remaining 51

**Skills** carry no model in Codex. For the 19 skills with an `agent:` field the
tier is inherited from the role automatically. The gap is the **7 haiku skills
with no owning role** — `help`, `onboard`, `project-stage-detect`, `scope-check`,
`sprint-status`, `story-readiness`, `changelog` — plus `review-all-gdds` on the
opus side. For these the generator appends an effort hint to the body:

> This is a mechanical read-and-format task. Do not over-deliberate.

Softer than a hard model pin. Accepted limitation.

### 6.6 Hook events

| Claude Code event | Codex | Status |
|---|---|---|
| `SessionStart` | `SessionStart` | ✅ |
| `PreToolUse` | `PreToolUse` | ✅ |
| `PostToolUse` | `PostToolUse` | ✅ |
| `PreCompact` | `PreCompact` | ✅ |
| `PostCompact` | `PostCompact` | ✅ |
| `Stop` | `Stop` | ✅ |
| `SubagentStart` | `SubagentStart` | ✅ |
| `SubagentStop` | `SubagentStop` | ✅ |
| `Notification` | — | ❌ **Drop `notify.sh`** |
| — | `SessionEnd`, `UserPromptSubmit`, `PermissionRequest`, `Interrupt` | Codex extras, unused |

**The hook scripts themselves need no changes.** Verified:

- **stdin fields are identical**: `session_id`, `transcript_path`, `cwd`,
  `hook_event_name`, `tool_name`, `tool_input`, plus `agent_id` / `agent_type`.
  Authoritative schemas: `codex-rs/hooks/schema/generated/*.schema.json`.
- **exit code 2 blocks**, same as Claude Code
  (`hooks/src/events/pre_tool_use.rs:261`).
- **matcher aliases**: Codex accepts `Bash`, `Write`, `Edit`, `Agent` explicitly
  for Claude Code compatibility (`core/src/tools/hook_names.rs`).

Our hooks read only `.tool_input.file_path`, `.tool_input.command`,
`.tool_input.path`, and `.message`, and use plain stdout + exit codes. All
supported.

**First-run friction:** Codex hashes and trusts hook configs
(`HookTrustStatus`). The first Codex session after the port will prompt to trust
`.codex/hooks.json`. Document this in the README so it does not read as a bug.

---

## 7. Phases

### Phase 0 — Scaffolding *(0.5 day)*

- Create `.codex/config.toml`: `[mcp_servers]` (2 servers from `.mcp.json`),
  `[agents]` (`max_concurrent_threads_per_session`, `default_subagent_model`),
  `[tools]` (the three gated tools from §6.3).
- Create `tools/codex-sync/` skeleton + `mappings.toml`.
- Add `.codex/` and `AGENTS.md` generated-file headers.

**Acceptance:** `codex` starts in the repo with both MCP servers initialising and
no config warnings.

### Phase 1 — Root instructions *(0.5 day)*

- Generator flattens `CLAUDE.md` + its 6 `@imports` into `AGENTS.md`.
- **Assert output < 32 KiB** (`DEFAULT_PROJECT_DOC_MAX_BYTES`) and fail the build
  otherwise. Current size 20 KB; headroom 12 KB.
- Optionally set `project_doc_fallback_filenames = ["CLAUDE.md"]` as a transition
  bridge.

**Acceptance:** `AGENTS.md` byte-identical across two consecutive generator runs;
Codex reports the project doc loaded.

**Outcome:** 20,554 bytes — 63% of the limit, 12,214 bytes headroom. Idempotent
(`--check` clean). All 6 imports resolved, 0 unrewritten skill references.
Imported headings are demoted to nest under their section, and an imported
title that merely restates the heading above it is dropped rather than
demoted. Surfaced R9.

### Phase 2 — Hooks *(0.5 day)*

- Generate `.codex/hooks.json` from the `hooks` block of `settings.json`.
- Drop the `Notification` entry (`notify.sh`).
- Point handlers at the existing `.claude/hooks/*.sh` — **no script changes.**

**Acceptance (corrected):** the original criterion said "a deliberately bad
commit message is blocked by `validate-commit.sh` with exit 2." That was wrong
on both counts — `validate-commit.sh` does not inspect commit *messages*, and
its message/style checks are advisory (warnings to stderr, `exit 0`). Its only
blocking path is a staged invalid `assets/data/*.json`. Corrected criterion:
every wired hook runs clean under Codex-shaped stdin, and `validate-commit.sh`
exits 2 on staged invalid JSON.

**Outcome:** all 11 wired hooks exercised with Codex-shaped stdin — all exit 0
with output identical to Claude Code; `validate-commit.sh` returns exit 2 on
staged invalid JSON and exit 0 on a non-commit command. 8 events emitted,
`Notification` dropped. Matchers verified to port verbatim: `""` is match-all
and `"Bash"` / `"Write|Edit"` are exact matchers in Codex too. The matcher is
stripped on `Stop`, where Codex ignores it. Surfaced R10.

Not verified: hooks firing inside a real Codex session (CLI not installed).

### Phase 3 — Agents *(2 days)*

- Generator converts 57 `.md` → `.toml`.
- Assert `name`, `description`, `developer_instructions` all present and non-blank.
- Apply the tier map from §6.5.
- **Write `deny-shell-for-roles.sh`** (§6.4) and generate its 15-name list from
  the `disallowedTools` frontmatter.

**Acceptance:** all 57 roles load with zero startup warnings
(`codex` prints agent-role warnings at startup — treat any as a failure);
`spawn_agent` with `game-designer` cannot run a shell command.

**Outcome:** 57 role files generated, all parse, zero schema problems, no keys
outside the four Codex reads. Effort distribution matches the tier map exactly
(3 high / 3 low / 51 medium). `model` left unset per open item #1 —
`model_reasoning_effort` carries the substance of D2 and does not depend on a
slug. Bodies are emitted as TOML *literal* strings (`'''`), which do no escape
processing, so markdown survives verbatim; the generator asserts the two things
a literal cannot hold. All 15 shell-denied roles carry the injected notice and
no others do; 0 unrewritten skill references. The deny-shell hook was tested
directly: exit 2 for `game-designer` and `writer`, exit 0 for
`gameplay-programmer` and for the main thread (no `agent_type`).

Not verified: roles loading inside a real Codex session (CLI not installed).

### Phase 4 — Skills *(3–4 days — the bulk)*

- Generator copies all 94, applying frontmatter transform (§6.1), the tool table
  (§6.3), and the `/x` → `$x` rewrite.
- **Rewrite safety:** only rewrite `/` followed by an exact match from the
  94-name list, anchored on a non-path-character boundary. `/gate-check` must be
  rewritten; `src/gameplay/` must not.
- **Validated in Phase 0.** Dry-run over all 151 source files: 991 rewrites,
  0 path false positives, 0 missed skill names. A crude regex would have caught
  85 extra tokens — `/summary`, `/root`, `/clear`, and `/div` (HTML closing
  tags) — all correctly skipped by the closed-name matcher.
- Inject delegation lines into the 19 skills with an `agent:` field.
- Inject effort hints into the 8 skills from §6.5.
- **Hand-convert the 9 `team-*` skills.** See risk R1.

**Acceptance:** all 94 skills appear in `/skills`; a spot-check of 10 skills
shows no surviving `/skill-name` or Claude tool names; the 9 `team-*` skills are
individually reviewed by a human, not just generated.

**Outcome:** 94 skills generated, frontmatter reduced to the two keys Codex
reads, 0 problems. Across all 94 skills *and* all 57 agent roles there are now
zero surviving `/skill-name` refs, `subagent_type`, `via Task`, `Task tool`,
`AskUserQuestion`, `TodoWrite`, `WebSearch` or `WebFetch`. Injections landed
exactly as scoped: 19 delegation notes, 9 orchestration notes, 8 effort hints,
1 isolation note.

**Bug found and fixed during this phase:** rewriting was applied to skill
*bodies* but not to frontmatter `description`. Descriptions are what Codex
matches on when selecting a skill, and they cross-reference other skills
(`Run after /brainstorm`, `Distinct from /project-stage-detect`) and name Claude
tools (`populates engine reference docs via WebSearch`). 12 skill refs and 1
tool name were leaking through. Agent `description` had the same gap — it feeds
`spawn_agent`'s `agent_type` guidance. Both now rewritten.

**R1 is NOT fully discharged.** The plan called for hand-converting the 9
`team-*` skills. What was actually done is systematic rather than bespoke: the
orchestration vocabulary turned out to be highly regular (`subagent_type` maps
1:1 onto Codex's `agent_type`, confirmed in `multi_agents_spec.rs`), so the
renames are mechanical, and a single reviewed orchestration block covering the
two real semantic gaps — no auto-routing, and the 6-thread concurrency cap — is
injected into all 9. That is a sound default, not a substitute for reading
them. Several `team-*` skills fan out to 7 roles, over the cap. **Each of the 9
still needs a human pass before it is trusted.**

### Phase 5 — Validation *(1–2 days)*

- Adapt `CCGS Skill Testing Framework` as the harness. Its specs are
  engine-agnostic prose and should mostly carry over; `catalog.yaml` and the
  agent/skill test specs may need a Codex variant.
- **Smoke-test one full vertical** end to end in Codex:
  `$brainstorm → $map-systems → $design-system → $create-epics → $dev-story`
- Wire the drift-guard CI job (§5).

**Acceptance:** the vertical completes in Codex producing the same artefact set
as Claude Code; drift guard fails on a hand-edited `.codex/` file.

---

## 8. Risk register

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| **R1** | **The 9 `team-*` skills assume Claude's parallel `Task` fan-out.** They are the largest skills (6–11 KB) and the most orchestration-dense. Codex has real parallelism via `max_concurrent_threads_per_session`, but will not auto-spawn custom roles — delegation must be explicit. | **High** | Hand-convert and hand-test all 9. Do not trust generator output. Budget most of Phase 4's slack here. |
| **R2** | `AGENTS.md` 32 KiB cap with only 12 KB headroom. Silent truncation would drop coordination rules. | Medium | Generator asserts and fails the build. Track as a standing budget. |
| **R3** | Losing shell-denial for 15 design agents. | Medium | `deny-shell-for-roles.sh` PreToolUse hook (§6.4). |
| **R4** | Per-skill model tiering is lossy for 8 skills. | Low | In-body effort hints; accept. |
| **R5** | `/x` → `$x` regex over-matching file paths. | Medium | Closed 94-name list + boundary anchoring + a unit test over known false-positive strings (`src/gameplay/`, `docs/engine-reference/`). |
| **R6** | Codex hook-trust prompt reads as a bug to new users. | Low | Document in README. |
| **R7** | Generator becomes stale / bypassed. | Medium | CI drift guard is the load-bearing control (§5). |
| **R8** | Model slugs move. | Low | Do not hardcode. Pin against the Codex model picker at port time, in `mappings.toml` only. |
| **R9** | **The source instruction chain declares three different engines.** `CLAUDE.md` says `[CHOOSE: Godot 4 / Unity / Unreal Engine 5]`, imports a pinned **Godot 4.6** version reference, and `technical-preferences.md` says **s&box / Source 2 / C#**. Pre-existing — Claude Code loads the same three via `@imports` — but flattening puts them ~70 lines apart in `AGENTS.md`, where the contradiction is unavoidable. | **High** | Not a port problem and not fixed here: the engine choice is a project decision. Resolve in `CLAUDE.md` + `technical-preferences.md`; `AGENTS.md` inherits the fix on the next sync. |
| **R10** | **`validate-sbox.sh` is not wired into `settings.json`.** It is the most blocking-heavy hook in the repo — 4 `exit 2` paths enforcing s&box conventions (no `using UnityEngine`, no `MonoBehaviour` inheritance, no Unity `Physics.*` API, valid `.sbproj` JSON) — and it is registered nowhere, so it has never run. | Medium | Pre-existing and **not fixed by the port**: the generator reads `settings.json`, so the hook stays inert in Codex exactly as in Claude Code. Wiring it is a behaviour change (it blocks) and belongs in a separate decision, not a port commit. |

---

### 6.7 `CLAUDE.md` references are deliberately not rewritten

27 references to `CLAUDE.md` survive across 12 skills and 1 agent. This is
intentional. A blanket rewrite to `AGENTS.md` would be actively wrong:
`AGENTS.md` is a *generated* file, so a skill like `$setup-engine` — which
*writes* the engine pin into `CLAUDE.md` — would be redirected into an artefact
that the next sync overwrites.

`CLAUDE.md` remains the source of truth under D3. Skills that read it still work
in Codex (the file is present and readable); skills that write it are writing to
the right place. A skill that edits `CLAUDE.md` leaves `AGENTS.md` stale, and
the CI drift guard catches exactly that — the system working as designed, not a
gap.

## 9. Non-goals and known losses

Accepted, with no planned mitigation:

- **Status line.** No Codex equivalent. The `<!-- STATUS -->` block in
  `active.md` remains useful to humans and skills; only the rendered line is lost.
- **`isolation: worktree`** on `prototype` / `prototyper`. Becomes a documented
  manual `git worktree` step.
- **`memory: user`** on 17 agents.
- **`maxTurns`** on all 57 agents.
- **Per-skill `allowed-tools`.**
- **`Notification` hook** (`notify.sh`).

---

## 10. Open items

1. **Model slugs** — pin `model = "..."` values against the installed Codex
   build before Phase 3. Deliberately unspecified here.
2. **Generator language** — Python assumed (repo already allows
   `python -m pytest` in `settings.json` permissions). Confirm.
3. **Testing framework port** — whether `CCGS Skill Testing Framework` gets a
   Codex variant or a shared engine-agnostic core. Decide at Phase 5.
4. **`.agents/skills/` convention** — Codex also reads this path, and it is
   becoming a cross-tool standard. Worth revisiting post-port as a possible
   replacement for `.codex/skills/`.
