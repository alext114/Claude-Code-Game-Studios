---
paths:
  - "code/**"
---

# s&box Code Rules

These rules apply to all files under `code/` in an s&box project.

## Architecture

- ALL game entity behaviors MUST be implemented as `Component` subclasses — never plain C# classes for game logic
- Components live in `code/Components/`, system managers in `code/Systems/`, UI panels in `code/UI/`
- NEVER create or reference a `src/` directory — s&box projects use `code/` exclusively
- Every Component file MUST have a matching class name (e.g., `PlayerController.cs` → `public sealed class PlayerController : Component`)

## Designer-Tunable Values

- ALL values that a designer might adjust MUST use the `[Property]` attribute
- NEVER hardcode gameplay values (speeds, damage, ranges, durations) as literals in logic methods
- Use `[Range(min, max)]` hints on float/int `[Property]` values where bounds are known
- Complex data tables and balance sheets belong in JSON files under `assets/data/`

```csharp
// Correct
[Property, Range(50f, 500f)] public float MoveSpeed { get; set; } = 200f;

// Incorrect — hardcoded value
var speed = 200f;  // VIOLATION
```

## Lifecycle Rules

- `OnUpdate()` — input reading, animation, non-physics logic ONLY
- `OnFixedUpdate()` — ALL physics, movement, and rigidbody forces ONLY
- NEVER put physics or movement code in `OnUpdate()`
- NEVER put input polling in `OnFixedUpdate()`
- Cache Component references in `OnStart()` — never call `Components.Get<T>()` in hot paths

## Multiplayer (Networked Components)

- ALL owner-only logic MUST begin with `if ( IsProxy ) return`
- ALL replicated state MUST use `[Sync]` — never implement manual state synchronization
- `[Sync]` properties MUST only be written from non-proxy instances
- Rpc methods for all-client events use `[Broadcast]`; server-only actions use `[Authority]`
- NEVER reference external networking libraries: Mirror, Netcode for GameObjects, Photon, etc.

```csharp
// Correct
protected override void OnUpdate()
{
    if ( IsProxy ) return;
    HandleInput();
}

// Incorrect — missing IsProxy guard
protected override void OnUpdate()
{
    HandleInput();  // VIOLATION: runs on all clients
}
```

## Physics Queries

- Use `Scene.Trace.Ray()` / `Scene.Trace.Sphere()` / `Scene.Trace.Box()` for ALL physics queries
- NEVER use `Physics.Raycast()`, `Physics.SphereCast()`, etc. — these are Unity APIs

```csharp
// Correct
var tr = Scene.Trace.Ray( origin, target ).Run();

// Incorrect — Unity API
Physics.Raycast( origin, direction );  // VIOLATION
```

## Performance

- NO per-frame heap allocations in `OnUpdate()` or `OnFixedUpdate()`:
  - No `new List<>()` in hot paths
  - No LINQ (`.Where()`, `.Select()`, etc.) in hot paths
  - No string concatenation in hot paths — use interpolated strings or `StringBuilder`
- Pre-allocate collections in fields; reuse them across frames

## Banned References

- `using UnityEngine;` — BLOCKED: this is not Unity
- `MonoBehaviour` — BLOCKED: use `Component` instead
- `Physics.Raycast` — BLOCKED: use `Scene.Trace` instead
- Any Unity namespace (`UnityEngine.*`, `UnityEditor.*`) — BLOCKED

## UI Code

- All UI lives in `code/UI/` as `.razor` + `.scss` file pairs
- UI panels MUST NOT own or mutate game state — read-only, event-raising only
- No in-Component UI creation: use Razor panels, not programmatic Widget/Canvas construction

## Examples

**Correct Component**:
```csharp
using Sandbox;

public sealed class DamageComponent : Component
{
    [Property, Range(1f, 500f)] public float Damage { get; set; } = 25f;
    [Property, Range(0f, 10f)] public float AttackRate { get; set; } = 1f;

    private float _nextAttackTime;

    protected override void OnUpdate()
    {
        if ( IsProxy ) return;
        if ( Time.Now >= _nextAttackTime && Input.Pressed( "Attack" ) )
        {
            PerformAttack();
            _nextAttackTime = Time.Now + (1f / AttackRate);
        }
    }

    private void PerformAttack()
    {
        var tr = Scene.Trace.Ray( Transform.Position, Transform.Forward * 100f )
            .WithoutTags( "player" )
            .Run();

        if ( tr.Hit )
        {
            tr.Component?.Components.Get<HealthComponent>()?.TakeDamage( Damage );
        }
    }
}
```

**Incorrect** (multiple violations):
```csharp
using UnityEngine;  // VIOLATION: Unity namespace

public class DamageComponent : MonoBehaviour  // VIOLATION: MonoBehaviour
{
    public float damage = 25f;  // VIOLATION: no [Property]

    void Update()  // VIOLATION: Unity lifecycle
    {
        // VIOLATION: Unity physics API
        if ( Physics.Raycast( transform.position, transform.forward, out var hit ) )
        {
            hit.collider.GetComponent<HealthComponent>()?.TakeDamage( damage );
        }
    }
}
```
