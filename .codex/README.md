# .codex/ — generated

Everything in this directory is emitted by `tools/codex-sync` from `.claude/`,
**except `config.toml`**, which is hand-maintained.

Do not hand-edit generated files. Edit the source under `.claude/`, then run:

```
python3 tools/codex-sync/sync.py
```

CI runs `sync.py --check` and fails if generated output is stale or has been
edited by hand. That drift guard is what makes dual Claude Code / Codex support
sustainable — it is not possible to land a `.claude/` change without the
matching regeneration.

| Path | Source | Status |
|---|---|---|
| `config.toml` | hand-maintained | ✅ |
| `hooks.json` | `.claude/settings.json` | ✅ |
| `agents/*.toml` | `.claude/agents/*.md` | ✅ |
| `hooks/deny-shell-for-roles.sh` | `disallowedTools` in `.claude/agents/*.md` | ✅ |
| `skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | ✅ |
| `../AGENTS.md` | `CLAUDE.md` + its `@imports` | ✅ |

See `docs/codex-port-plan.md`.

## Editing CLAUDE.md

`CLAUDE.md` stays the source of truth; `AGENTS.md` is generated from it. If a
skill or a human edits `CLAUDE.md`, `AGENTS.md` goes stale and the drift guard
fails. Re-run the sync. That is the intended workflow, not a bug.

## First run

Codex hashes and trusts hook configs. The first Codex session after `hooks.json`
lands will prompt to trust it. That is expected, not a bug.
