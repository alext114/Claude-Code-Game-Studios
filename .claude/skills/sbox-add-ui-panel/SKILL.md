---
name: sbox-add-ui-panel
description: "Scaffold a new s&box Razor UI panel: generates a .razor file and matching .scss file in code/UI/. The panel reads Component state via [Property] bindings and raises events for interactions — it never owns or mutates game state."
argument-hint: "<PanelName> (e.g., 'HudPanel', 'InventoryPanel', 'MainMenuPanel')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite
---

When this skill is invoked:

## 1. Parse Arguments

- If `<PanelName>` was provided, normalize to PascalCase + ensure it ends in `Panel`
  (e.g., `hud` → `HudPanel`, `inventory` → `InventoryPanel`)
- If no argument, ask: "What should this panel be named? (e.g., `HudPanel`, `InventoryPanel`)"

---

## 2. Check Existing State

- Check if `code/UI/[PanelName].razor` already exists
  - If yes, ask: "This panel already exists. Update it, or use a different name?"
- Check `design/gdd/` for any UI design document for this panel — extract display requirements

---

## 3. Ask Panel Questions

1. **What does this panel display?** (e.g., "health bar, ammo count, minimap")
2. **What game Components does it need to read from?** (e.g., `HealthComponent`, `AmmoComponent`)
   — these become `[Property]` bindings on the panel
3. **Does the player interact with it?** (buttons, sliders, input fields — if yes, what actions?)
   — interactions raise events, never mutate Components directly
4. **Where does it appear on screen?** (HUD overlay, fullscreen menu, world-space?)
5. **Any specific visual style needs?** (color scheme, animations, size hints)

---

## 4. Generate and Preview

Draft both files based on the answers. Show them before writing.

**Example: HudPanel.razor**
```razor
@using Sandbox;
@using Sandbox.UI;

@inherits Panel

<root class="hud-panel">
    <div class="health-section">
        <div class="health-bar">
            <div class="health-fill" style="width: @(HealthPercent * 100f)%"></div>
        </div>
        <label class="health-text">@HealthText</label>
    </div>

    <div class="ammo-section">
        <label class="ammo-count">@AmmoText</label>
    </div>
</root>

@code {
    /// <summary>Health source — set by the owning player Component.</summary>
    [Property] public HealthComponent HealthSource { get; set; }

    /// <summary>Ammo source — set by the weapon Component.</summary>
    [Property] public AmmoComponent AmmoSource { get; set; }

    float HealthPercent => HealthSource is not null
        ? MathF.Max( 0f, HealthSource.CurrentHealth / HealthSource.MaxHealth )
        : 1f;

    string HealthText => HealthSource is not null
        ? $"{(int)HealthSource.CurrentHealth} / {(int)HealthSource.MaxHealth}"
        : "-- / --";

    string AmmoText => AmmoSource is not null
        ? $"{AmmoSource.CurrentAmmo} / {AmmoSource.MaxAmmo}"
        : "-- / --";
}
```

**Example: HudPanel.razor.scss**
```scss
.hud-panel {
    position: absolute;
    bottom: 24px;
    left: 24px;
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.health-bar {
    width: 220px;
    height: 14px;
    background: rgba(0, 0, 0, 0.55);
    border-radius: 3px;
    overflow: hidden;

    .health-fill {
        height: 100%;
        background: #27ae60;
        transition: width 0.15s ease;
    }
}

.health-text,
.ammo-count {
    color: white;
    font-size: 14px;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
}
```

Ask: "Does this match what you need? Any layout, data, or style changes?"

---

## 5. Write the Files

After approval, write both files:
- `code/UI/[PanelName].razor`
- `code/UI/[PanelName].razor.scss`

If `code/UI/` doesn't exist, note this — it should have been created by `/setup-engine sbox`.

---

## 6. Explain How to Mount the Panel

After writing, explain how to attach the panel in-game:

> To show this panel, a Component (typically a Player or UI Manager Component) instantiates it:
>
> ```csharp
> // In a Component's OnStart or when the player is created:
> var hud = Panel.Create<HudPanel>( Game.RootPanel );
> hud.HealthSource = Components.Get<HealthComponent>();
> hud.AmmoSource = Components.Get<AmmoComponent>();
> ```
>
> Or add it to a scene via the s&box editor by placing a `PanelComponent` and pointing it at this panel type.

---

## 7. Offer Next Steps

```
Panel created:
  code/UI/[PanelName].razor
  code/UI/[PanelName].razor.scss

Next steps:
- /sbox-add-ui-panel [AnotherPanel]  — add another panel
- /sbox-create-component             — create a Component to drive this panel
- /code-review code/UI/              — validate UI code
```

---

## Guardrails

- NEVER use Unity UI APIs (`using UnityEngine.UI`, `Canvas`, `RectTransform`, `Image`)
- UI files live in `code/UI/` — never in `code/Components/`
- Panels are READ-ONLY: they read `[Property]` bindings, they never write to Components
- Interactions (button clicks) raise events or call methods on a coordinating Component
- Every `.razor` file gets a companion `.razor.scss` — no inline styles in the razor template
- If the user describes a Unity UGUI setup, explain the Razor equivalent
