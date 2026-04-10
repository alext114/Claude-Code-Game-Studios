---
name: sbox-create-player-controller
description: "Scaffold a complete s&box PlayerController Component using the PlayerController + WishVelocity API (NOT CharacterController), configurable [Property] values, input handling in OnUpdate, physics in OnFixedUpdate, and IsProxy guards for multiplayer. Writes to Code/Components/PlayerController.cs."
argument-hint: "[no arguments — guided workflow]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Check Existing State

- Check if `code/Components/PlayerController.cs` already exists
  - If yes: "A PlayerController already exists. Should I (A) update it in place, (B) create a different name, or (C) view what's there first?"
- Check `design/gdd/` for any player movement design document — extract specs if found
- Check `docs/engine-reference/sbox/VERSION.md` for any API warnings

---

## 2. Ask Configuration Questions

Ask these questions (can use AskUserQuestion for grouped answers):

1. **Movement type**: Standard FPS/TPS ground movement, or something custom (swimming, flying, vehicle)?
2. **Jump**: Does the player jump? (yes/no — if yes, ask: single jump or double jump?)
3. **Multiplayer**: Will this game be multiplayer? (determines IsProxy guards and [Sync] usage)
4. **Camera**: Does the controller also handle camera rotation? (or is that a separate Component?)
5. **Tuning values**: Any specific move speed, jump force, or gravity values? (or use sensible defaults)

---

## 3. Generate and Preview

Draft the full PlayerController based on answers. Show the complete code before writing.

> **IMPORTANT:** s&box uses `PlayerController` + `WishVelocity` — NOT the old `CharacterController` + `.Move()`.
> `CharacterController` was removed in a breaking change. The built-in `PlayerController` component handles
> gravity, ground friction, and stepping automatically. Set `WishVelocity` each `OnFixedUpdate`.

**Template for standard multiplayer TPS controller (Los Manos style):**

```csharp
/// <summary>
/// Handles player movement intent. Requires a PlayerController Component on the same GameObject.
/// Input is read in OnUpdate; physics is applied in OnFixedUpdate via WishVelocity.
/// All tuning values are exposed as [Property] for designer adjustment.
/// </summary>
[RequireComponent( typeof( PlayerController ) )]
public sealed class PlayerMovement : Component
{
    [Property, Group( "Movement" ), Range( 200f, 500f )]
    public float WalkSpeed { get; set; } = 350f;

    [Property, Group( "Movement" ), Range( 400f, 700f )]
    public float SprintSpeed { get; set; } = 550f;

    [Property, Group( "Movement" ), Range( 250f, 500f )]
    public float JumpImpulse { get; set; } = 380f;

    [Property, Group( "Movement" ), Range( 0f, 1f )]
    public float AirControlFactor { get; set; } = 0.3f;

    private PlayerController _controller;
    private Vector3 _wishVelocity;
    private bool _jumpPressed;

    protected override void OnStart()
    {
        _controller = Components.Get<PlayerController>();
    }

    protected override void OnUpdate()
    {
        if ( IsProxy ) return;

        // Read input in OnUpdate — store intent for OnFixedUpdate, never apply physics here
        var wishDir = Input.AnalogMove.Normal;
        var isSprinting = Input.Down( "Sprint" ) && _controller.IsOnGround;
        var speed = isSprinting ? SprintSpeed : WalkSpeed;
        var controlFactor = _controller.IsOnGround ? 1f : AirControlFactor;

        _wishVelocity = Transform.Rotation * new Vector3( wishDir.x, wishDir.y, 0f ) * speed * controlFactor;

        if ( Input.Pressed( "Jump" ) && _controller.IsOnGround )
        {
            _jumpPressed = true;
        }
    }

    protected override void OnFixedUpdate()
    {
        if ( IsProxy ) return;

        // Apply movement in OnFixedUpdate — never read Input.* here
        _controller.WishVelocity = _wishVelocity;

        if ( _jumpPressed )
        {
            _controller.Punch( Vector3.Up * JumpImpulse );
            _controller.PreventGrounding();
            _jumpPressed = false;
        }
    }
}
```

Ask: "Does this match your design? Any values or features to adjust before I write the file?"

---

## 4. Write the File

After approval, write to `Code/Components/PlayerMovement.cs` (or a path under `Code/` appropriate to the project structure).

Remind the user to add the built-in `PlayerController` Component to the player prefab in the s&box editor
(it is a built-in engine Component, not a script file — you add it via the editor inspector).

---

## 5. Offer Next Steps

```
PlayerController created: code/Components/PlayerController.cs

Next steps:
1. Add a CharacterController Component to your player prefab in the s&box editor
2. /sbox-setup-multiplayer  — review IsProxy usage and [Sync] properties
3. /sbox-add-ui-panel       — add a HUD to show player state
4. /code-review code/Components/PlayerController.cs — validate against s&box rules
```

---

## Guardrails

- NEVER use `CharacterController` — it is the old API, removed in a breaking change
- NEVER call `_controller.Move(velocity * Time.Delta)` — that is the old CharacterController pattern
- NEVER assign `Rigidbody.Velocity = x` — use `ApplyImpulse()` for instantaneous velocity changes
- NEVER use `Physics.Raycast` for ground detection — use `_controller.IsOnGround`
- NEVER skip `IsProxy` for a multiplayer game
- NEVER read `Input.*` in `OnFixedUpdate` — read input in `OnUpdate`, apply intent in `OnFixedUpdate`
- Set `WishVelocity` each `OnFixedUpdate` — this is how `PlayerController` moves
- Use `Punch( Vector3 )` + `PreventGrounding()` for jump impulses
- If the user describes Unity-style movement code, explain s&box equivalents
