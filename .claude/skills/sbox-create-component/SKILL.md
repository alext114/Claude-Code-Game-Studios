---
name: sbox-create-component
description: "Scaffold a new s&box Component with correct lifecycle methods, [Property] attributes, IsProxy guards, and XML doc comments. Writes to code/Components/."
argument-hint: "<ComponentName> (e.g., 'HealthComponent', 'WeaponController')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Parse Arguments

- If `<ComponentName>` was provided, use it — normalize to PascalCase
- If no argument was provided, ask: "What should this Component be named? (PascalCase, e.g., `HealthComponent`)"

---

## 2. Gather Context

Before generating code:

- Check `docs/engine-reference/sbox/VERSION.md` if it exists — note any API warnings
- Check if a Component with this name already exists in `code/Components/`
  - If it does, ask: "A Component named `[Name]` already exists at `code/Components/[Name].cs`. Should I update it, or use a different name?"
- Check if there is a design document for this system in `design/gdd/` — extract relevant properties and rules

---

## 3. Ask Component Questions

Ask the user (use AskUserQuestion with multiple questions if helpful):

1. **What does this Component do?** (one sentence — this becomes the XML doc summary)
2. **What [Property] values does it need?** (name, type, default, range if applicable — e.g., "MoveSpeed: float, default 200, range 50–500")
3. **Does it need physics?** (OnFixedUpdate) or is it input/visual only? (OnUpdate only)
4. **Is it networked?** (will it exist in a multiplayer game and need IsProxy guards?)
5. **Does it depend on other Components?** (e.g., needs `CharacterController`, `HealthComponent`) — these become `RequireComponent` or `Components.Get<T>()` in `OnStart()`

---

## 4. Generate and Preview

Draft the Component code based on the answers. Show it to the user before writing:

```csharp
using Sandbox;

/// <summary>
/// [Description from question 1]
/// </summary>
public sealed class [ComponentName] : Component
{
    // [Property] fields from question 2
    [Property, Range(min, max)] public [Type] [Name] { get; set; } = [default];

    // Cached references from question 5
    private [DependencyType] _dependency;

    protected override void OnStart()
    {
        _dependency = Components.Get<[DependencyType]>();
    }

    // Only if question 3 = needs OnUpdate
    protected override void OnUpdate()
    {
        if ( IsProxy ) return;  // Only if question 4 = networked
        // TODO: implement OnUpdate logic
    }

    // Only if question 3 = needs physics
    protected override void OnFixedUpdate()
    {
        if ( IsProxy ) return;  // Only if question 4 = networked
        // TODO: implement OnFixedUpdate logic
    }
}
```

Ask: "Does this look right? Any changes before I write the file?"

---

## 5. Write the File

After approval, write to `code/Components/[ComponentName].cs`.

If the directory doesn't exist, note this to the user — in a fresh s&box project it
should already exist from `/setup-engine sbox`.

---

## 6. Offer Next Steps

After writing:

```
Component created: code/Components/[ComponentName].cs

Next steps:
- /sbox-create-component [RelatedName]  — create a related Component
- /sbox-setup-multiplayer               — audit this Component's networking
- /code-review code/Components/[Name].cs — validate against s&box rules
```

---

## Guardrails

- NEVER generate `MonoBehaviour` — always `Component`
- NEVER write to `src/` — always `code/Components/`
- NEVER hardcode values that should be `[Property]`
- ALWAYS add `if ( IsProxy ) return` if the Component will be used in multiplayer
- ALWAYS use `OnFixedUpdate` for physics, `OnUpdate` for input
- If the user asks for a Unity-style Component, explain the s&box equivalent and generate the correct version
