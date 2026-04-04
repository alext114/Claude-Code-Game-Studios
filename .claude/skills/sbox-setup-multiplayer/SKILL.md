---
name: sbox-setup-multiplayer
description: "Audit existing s&box Components for multiplayer correctness: checks IsProxy guards, identifies replicated state needing [Sync], reviews Rpc methods, and generates a NetworkSummary.md architecture document."
argument-hint: "[optional: component name or 'audit' to scan all code/Components/]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Parse Arguments

- If a Component name is given (e.g., `/sbox-setup-multiplayer PlayerController`): focus on that file
- If `audit` or no argument: scan all `.cs` files under `code/` for networking issues

---

## 2. Teach the Networking Model (First Time)

If no `docs/architecture/NetworkSummary.md` exists, give a brief explanation before auditing:

> **s&box Multiplayer is built-in.** There are three core concepts:
>
> - **`IsProxy`** — `true` when this Component instance represents a remote player.
>   All owner-only logic (input, UI, camera) must be gated: `if ( IsProxy ) return`
>
> - **`[Sync]`** — Marks a property for automatic replication.
>   Set it only on the owning instance; proxies receive updates automatically.
>   ```csharp
>   [Sync] public float Health { get; set; }
>   ```
>
> - **Rpc methods** — Remote procedure calls across the network:
>   - `[Broadcast]` — called on owner, runs on ALL clients (visual/audio effects)
>   - `[Authority]` — called on any client, runs only on the SERVER/HOST (gameplay logic)

Ask: "Do you want me to explain more, or should I proceed with the audit?"

---

## 3. Scan Components

Read all `.cs` files in `code/Components/` and `code/Systems/`. For each file, check:

### IsProxy Audit
- Does any `OnUpdate()` contain code that should be owner-only?
  - Input reading? → needs `if ( IsProxy ) return`
  - Camera control? → needs `if ( IsProxy ) return`
  - UI updates driven by this Component? → needs `if ( IsProxy ) return`
- Does `OnFixedUpdate()` contain movement/physics? → needs `if ( IsProxy ) return`

### Sync Audit
- Identify properties that represent game state other clients need to see:
  - Health, ammo, score, position-override values, state machine state, etc.
  - These should be `[Sync]`
- Flag any properties that are being set without checking `IsProxy`

### Rpc Audit
- Identify methods that trigger effects visible to all players → should be `[Broadcast]`
- Identify methods that perform server-authoritative actions → should be `[Authority]`

---

## 4. Report Findings

Present a structured report:

```
Multiplayer Audit Results
=========================

✅ CORRECT
  - PlayerController.OnUpdate: IsProxy guard present
  - HealthComponent.CurrentHealth: [Sync] applied

⚠️  NEEDS ATTENTION
  - WeaponController.OnUpdate (line 34): No IsProxy guard — input will run on all clients
  - DamageComponent.Damage: Value changes not replicated — consider [Sync]
  - EffectsComponent.PlayHitEffect(): Called on owner but should run on all clients — needs [Broadcast]

🚫 BLOCKING ISSUES
  - (none)
```

Ask: "Should I apply the recommended fixes? I'll show you each change before writing."

---

## 5. Apply Fixes (with Approval)

For each finding, show the before/after diff and ask: "May I apply this fix to [filepath]?"

Apply fixes one file at a time.

---

## 6. Generate NetworkSummary.md

After the audit (and optional fixes), generate `docs/architecture/NetworkSummary.md`:

```markdown
# Network Architecture Summary

Generated: [date]
Engine: s&box (built-in networking)

## Replicated Components

| Component | [Sync] Properties | Owner-Only Methods | Rpc Methods |
|-----------|------------------|-------------------|-------------|
| PlayerController | — | OnUpdate, OnFixedUpdate | — |
| HealthComponent | CurrentHealth, IsAlive | TakeDamage | OnDeathEffect [Broadcast] |
| WeaponController | CurrentAmmo | Fire, Reload | FireEffect [Broadcast] |

## Sync Point Notes

[Any architectural notes about why certain choices were made]

## Known Limitations

[List any compromises or TODOs in the networking design]
```

Ask: "May I write this to `docs/architecture/NetworkSummary.md`?"

---

## 7. Offer Next Steps

```
Multiplayer setup complete.

Next steps:
- /code-review code/Components/ — final code quality pass
- /sbox-create-component        — add more networked Components
- /sprint-plan new              — plan your first networked feature sprint
```

---

## Guardrails

- NEVER suggest external networking libraries (Mirror, Netcode, Photon, etc.)
- Only apply fixes with explicit per-file approval
- Explain each networking concept before applying it — don't just add attributes blindly
- `[Sync]` on a property does not mean it can be set from proxy instances — always clarify this
