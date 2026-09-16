# codex-sync

Generates `.codex/` and `AGENTS.md` from `.claude/`.

`.claude/` is the single source of truth and stays written in Claude Code idiom
— `/skill-name` references, Claude tool names, the full frontmatter vocabulary.
This script translates that into what Codex reads.

## Usage

```
python3 tools/codex-sync/sync.py              # generate
python3 tools/codex-sync/sync.py --check      # drift guard (CI)
python3 tools/codex-sync/sync.py --self-test  # rewrite-rule test cases
python3 tools/codex-sync/sync.py --status     # what is discovered
```

## Why a generator

Every Claude/Codex divergence is a *closed, enumerable* mapping — 94 known skill
names, 12 tool renames, a fixed frontmatter key list, a 3-value tier map. That
makes the port scriptable rather than editorial, which is what keeps dual
support from becoming double maintenance. All of it lives in `mappings.toml`.

## The two rewrite classes

`rewrite_tool_names` deliberately treats two groups differently:

- **Safe** names are CamelCase and not English words, so they are rewritten
  wherever they appear.
- **Contextual** names (`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `Task`)
  are ordinary English words. Rewriting them bare would turn "Read the story
  file" into "read_file the story file", so they are rewritten only inside
  backticks or in an explicit "X tool" phrasing.

Skill references (`/x` → `$x`) are matched against the closed set of 94 real
skill names with path-boundary guards, so `/help` is rewritten but `docs/help/`
and `</div>` are not. Validated over all 151 source files: 991 rewrites, zero
false positives. `--self-test` covers the boundary cases.

## Status

Phase 0 (scaffolding, mappings, shared rewriting) is implemented. Phases 1–4
are explicit stubs. See `docs/codex-port-plan.md`.
