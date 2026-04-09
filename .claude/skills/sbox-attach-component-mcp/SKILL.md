---
name: sbox-attach-component-mcp
description: "Attach a built-in s&box Component to an existing GameObject via MCP, configure its [Property] values, and verify the result. Use this for engine-native components (CharacterController, Rigidbody, etc.) without writing any C# code."
argument-hint: "<EntityName> <ComponentType> (e.g., 'Player CharacterController')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

When this skill is invoked:

> **Requires**: s&box MCP server running at `localhost:8098`.
> For custom C# Components that require new source code, use `/sbox-create-component` first, then return here to attach and configure it.

## 1. Parse Arguments

- Extract entity name and component type from argument
- If either is missing, ask:
  1. "Which entity should the component be added to? (name or describe)"
  2. "Which component type? (e.g., CharacterController, Rigidbody, ModelRenderer)"

---

## 2. Discover Available Component Types

If the component type is uncertain or the user says "not sure":
Call `get_component_types { filter: "<keyword>" }` via MCP.

Present the filtered list and ask: "Which of these did you mean?"

---

## 3. Find the Target Entity

Call `find_game_objects { nameContains: "<EntityName>", maxResults: 10 }` via MCP.

If no match: "No GameObject named `[Name]` found. Run `/sbox-spawn-entity [Name]` first."
If multiple matches: present list and ask user to confirm the correct one.

Capture target GUID.

---

## 4. Check for Existing Component

Call `get_game_object_details { id: "<GUID>" }` via MCP.

If the component already exists on the object:
- Report: "`[ComponentType]` is already attached to `[EntityName]`. Should I (A) reconfigure its properties, or (B) skip and move on?"

---

## 5. Probe Component Properties

To discover all available `[Property]` fields before setting values:

```
1. create_game_object { name: "__MCPProbe__" }  → probe GUID
2. add_component { id: probeGUID, componentType: "<ComponentType>" }
3. get_component_properties { id: probeGUID, componentType: "<ComponentType>" }
   → capture all property names and default values
4. destroy_game_object { id: probeGUID }
```

Present the discovered properties to the user:
```
Available properties for [ComponentType]:
  Radius: float = 16
  Height: float = 64
  StepHeight: float = 18
  GroundAngle: float = 45
  ...
Which would you like to configure? (press enter to use defaults)
```

---

## 6. Attach the Component

Call `add_component { id: "<GUID>", componentType: "<ComponentType>" }` via MCP.

Confirm success message returned.

---

## 7. Configure Properties

For each property the user wants to set:
Call `set_component_property { id: "<GUID>", componentType: "<ComponentType>", propertyName: "<Name>", value: "<Value>" }` via MCP.

Supported value types:
- Primitives: `"200"`, `"true"`, `"false"`
- Vector3: `{"x": 0, "y": 0, "z": 0}`
- Enum: `"Box"`, `"Sphere"`, etc.
- GameObject reference: GUID string of another object
- Component reference: GUID string of the source object

---

## 8. Verify Final State

Call `get_component_properties { id: "<GUID>", componentType: "<ComponentType>" }` via MCP.

Compare returned values against what was set. Report any mismatches.

```
✅ Component attached: [ComponentType] on [EntityName]
   Radius: 16
   Height: 64
   StepHeight: 18
   [any others configured]
```

---

## 9. Offer Next Steps

```
Component attached and configured.

Next steps:
- /sbox-attach-component-mcp [EntityName] <AnotherComponent>  — add more components
- /sbox-create-component <CustomLogicName>                     — write custom C# logic
- /sbox-setup-multiplayer                                      — audit networking if multiplayer
- /sbox-playmode-test                                          — run and verify in play mode
```

---

## Guardrails

- NEVER guess property names — always probe with the TypeLibrary step first
- If `add_component` fails with "type not found", the component either doesn't exist or hasn't been compiled yet — suggest the user check that their C# file has no errors
- NEVER attach components to objects named `__MCPProbe__` — always destroy the probe object
- For custom Components (user-written C#), remind the user that the `.cs` file must be compiled (hotloaded) before the type appears in TypeLibrary
