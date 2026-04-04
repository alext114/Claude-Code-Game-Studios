---
name: sbox-create-player-controller
description: "Scaffold a complete s&box PlayerController Component with CharacterController movement, configurable [Property] values, input handling in OnUpdate, physics in OnFixedUpdate, and IsProxy guards for multiplayer. Writes to code/Components/PlayerController.cs."
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

**Template for standard multiplayer FPS controller:**

```csharp
using Sandbox;

/// <summary>
/// Handles player movement, jumping, and ground detection.
/// Requires a CharacterController Component on the same GameObject.
/// All tuning values are exposed as [Property] for designer adjustment.
/// </summary>
[RequireComponent( typeof( CharacterController ) )]
public sealed class PlayerController : Component
{
    [Property, Group( "Movement" ), Range( 50f, 600f )]
    public float MoveSpeed { get; set; } = 250f;

    [Property, Group( "Movement" ), Range( 100f, 800f )]
    public float JumpForce { get; set; } = 350f;

    [Property, Group( "Movement" ), Range( 5f, 60f )]
    public float Gravity { get; set; } = 25f;

    // [Only if camera handling requested]
    [Property, Group( "Camera" ), Range( 0.1f, 10f )]
    public float MouseSensitivity { get; set; } = 1f;

    private CharacterController _controller;
    private Vector3 _velocity;
    private Vector3 _wishVelocity;
    private Angles _eyeAngles;

    protected override void OnStart()
    {
        _controller = Components.Get<CharacterController>();
    }

    protected override void OnUpdate()
    {
        if ( IsProxy ) return;

        // Camera rotation (if camera handling enabled)
        _eyeAngles.pitch += Input.MouseDelta.y * MouseSensitivity * -0.1f;
        _eyeAngles.yaw += Input.MouseDelta.x * MouseSensitivity * 0.1f;
        _eyeAngles.pitch = _eyeAngles.pitch.Clamp( -80f, 80f );
        Transform.Rotation = Rotation.From( 0f, _eyeAngles.yaw, 0f );

        // Capture move intent in OnUpdate — applied in OnFixedUpdate
        var wishDir = Input.AnalogMove.Normal;
        _wishVelocity = Transform.Rotation * new Vector3( wishDir.x, wishDir.y, 0f ) * MoveSpeed;

        // Jump intent — captured here, applied in OnFixedUpdate
        if ( Input.Pressed( "Jump" ) && _controller.IsOnGround )
        {
            _velocity.z = JumpForce;
        }
    }

    protected override void OnFixedUpdate()
    {
        if ( IsProxy ) return;

        // Apply stored wish velocity — never read Input.* here
        _velocity.x = _wishVelocity.x;
        _velocity.y = _wishVelocity.y;

        // Gravity
        if ( !_controller.IsOnGround )
        {
            _velocity.z -= Gravity * Time.Delta;
        }
        else if ( _velocity.z < 0f )
        {
            _velocity.z = 0f;
        }

        _controller.Move( _velocity * Time.Delta );
    }
}
```

Ask: "Does this match your design? Any values or features to adjust before I write the file?"

---

## 4. Write the File

After approval, write to `code/Components/PlayerController.cs`.

If a CharacterController Component is needed, remind the user to add it to the player
prefab in the s&box editor (it's a built-in Component, not a script file).

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

- NEVER generate `CharacterController` via `new` — it must be a Component on the GameObject
- NEVER use `Physics.Raycast` for ground detection — use `_controller.IsOnGround`
- NEVER skip `IsProxy` for a multiplayer game
- Input reading always in `OnUpdate`, movement always in `OnFixedUpdate`
- If the user describes Unity-style movement code, explain s&box equivalents
