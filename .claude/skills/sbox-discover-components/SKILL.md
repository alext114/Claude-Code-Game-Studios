---
name: sbox-discover-components
description: "Browse and search available Component types in the active s&box TypeLibrary via MCP. Use to find what built-in components are available before attaching them, or to verify a custom C# Component has compiled successfully."
argument-hint: "[optional: search keyword, e.g., 'physics', 'nav', 'render', 'collider']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> TypeLibrary reflects the current compiled state — custom Components appear here after hotload.

## 1. Parse Arguments

- If keyword provided: search for component types matching that keyword
- If not provided: ask "What kind of component are you looking for? (e.g., 'physics', 'nav', 'audio', 'render') or say 'all' to list everything"

---

## 2. Query TypeLibrary

Call `get_component_types { filter: "<keyword>" }` via MCP.

If keyword is "all" or empty: call with no filter to get all available types.

---

## 3. Organize Results

Group discovered types by category:

**Physics & Movement:**
- CharacterController, Rigidbody, Collider variants (BoxCollider, SphereCollider, etc.)

**Navigation & AI:**
- NavMeshAgent, NavMeshArea, NavMeshLink

**Rendering:**
- ModelRenderer, SkinnedModelRenderer, SpotLight, PointLight, AmbientLight

**UI:**
- PanelComponent, WorldPanel

**Audio:**
- SoundComponent, AudioListener

**Scripted (custom C#):**
- Any types not in the above categories — these are user-authored Components

---

## 4. Probe Default Properties (optional)

If the user wants to see default property values for a specific type:

```
1. create_game_object { name: "__TypeProbe__" }  → probeGUID
2. add_component { id: probeGUID, componentType: "<TypeName>" }
3. get_component_properties { id: probeGUID, componentType: "<TypeName>" }
   → display all properties + default values
4. destroy_game_object { id: probeGUID }
```

Present results:
```
Component: CharacterController
  Radius:      float = 16
  Height:      float = 64
  StepHeight:  float = 18
  GroundAngle: float = 45
  Mass:        float = 1
```

---

## 5. Check Custom Component Compilation

If the user is looking for a custom C# Component that isn't appearing:

1. Ask: "Which custom Component are you expecting to find?"
2. Check `code/Components/<Name>.cs` exists via Glob
3. If file exists but type not in TypeLibrary → compile error; run:
   Call `get_editor_log { lines: 30 }` via MCP → look for C# errors
4. Report: "Component `[Name]` is not compiled yet. Check the editor log for errors."

---

## 6. Report

```
🔍 Component types found: [N] matching "<keyword>"

Physics & Movement ([N]):
  - CharacterController
  - Rigidbody

Navigation ([N]):
  - NavMeshAgent
  - NavMeshArea

[etc.]

Custom Components ([N]):
  - [UserDefinedType1]
  - [UserDefinedType2]
```

---

## 7. Offer Next Steps

```
- /sbox-attach-component-mcp <EntityName> <ComponentType>  — attach a discovered component
- /sbox-create-component <NewName>                          — create a new custom component
- /sbox-hotreload-iterate <ExistingName>                    — fix compile issues for a component
```

---

## Guardrails

- ALWAYS destroy the probe object after property inspection — never leave `__TypeProbe__` in the scene
- TypeLibrary only shows compiled types — if a custom component is missing, it hasn't compiled yet
- Some component types are abstract base classes and cannot be added directly — note this if `add_component` fails
- Filter results to avoid flooding the user with hundreds of engine-internal types — focus on actionable ones
