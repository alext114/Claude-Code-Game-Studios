#!/bin/bash
# Claude Code PostToolUse hook: Validates s&box code files after Write/Edit
# Fires when files under code/ are written or edited.
# Receives JSON on stdin with tool_input.file_path (Write) or tool_input.path (Edit).
#
# Exit 0 always (PostToolUse cannot block), but emits warnings/errors to stderr.
# EXCEPTION: Unity namespace detection emits a blocking message via stderr and exits 2
# to signal Claude it must fix the issue before proceeding.
#
# Input schema (PostToolUse for Write/Edit):
# { "tool_name": "Write"|"Edit", "tool_input": { "file_path": "...", ... } }

INPUT=$(cat)

# Parse file path -- try jq first, fall back to grep
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
else
    FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
    if [ -z "$FILE_PATH" ]; then
        FILE_PATH=$(echo "$INPUT" | grep -oE '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"path"[[:space:]]*:[[:space:]]*"//;s/"$//')
    fi
fi

# Normalize Windows backslashes to forward slashes
FILE_PATH=$(echo "$FILE_PATH" | tr '\\' '/')

# Only process files under code/
if ! echo "$FILE_PATH" | grep -qE '(^|/)code/'; then
    exit 0
fi

# File must exist and be readable
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

WARNINGS=""
BLOCKED=""

# ── .cs file checks ──────────────────────────────────────────────────────────
if echo "$FILE_PATH" | grep -qE '\.cs$'; then

    # BLOCKING: Unity namespace import
    if grep -nE '^[[:space:]]*using[[:space:]]+UnityEngine' "$FILE_PATH" 2>/dev/null; then
        echo "BLOCKED: $FILE_PATH contains 'using UnityEngine' — this is an s&box project, not Unity. Use 'using Sandbox;' instead." >&2
        exit 2
    fi

    # BLOCKING: MonoBehaviour inheritance
    if grep -nE ':[[:space:]]*(MonoBehaviour|NetworkBehaviour)[[:space:]]*($|{|,)' "$FILE_PATH" 2>/dev/null; then
        echo "BLOCKED: $FILE_PATH inherits from MonoBehaviour/NetworkBehaviour — this is s&box. Classes must inherit from Component (using Sandbox;)." >&2
        exit 2
    fi

    # BLOCKING: Unity Physics API
    if grep -nE 'Physics\.(Raycast|SphereCast|BoxCast|CapsuleCast|OverlapSphere|OverlapBox)' "$FILE_PATH" 2>/dev/null; then
        echo "BLOCKED: $FILE_PATH uses Unity Physics API. In s&box, use Scene.Trace.Ray()/Sphere()/Box().Run() instead." >&2
        exit 2
    fi

    # Warning: class does not inherit Component (heuristic — skip interfaces, structs, enums, static classes)
    # Only warn for classes in code/Components/ that don't seem to be test/data classes
    if echo "$FILE_PATH" | grep -qE '(^|/)code/Components/'; then
        if grep -qE '^[[:space:]]*(public|internal)[[:space:]]+(sealed[[:space:]]+)?class[[:space:]]+' "$FILE_PATH" 2>/dev/null; then
            if ! grep -qE ':[[:space:]]*(Component|Panel|RootPanel)' "$FILE_PATH" 2>/dev/null; then
                WARNINGS="$WARNINGS\nSBOX: $FILE_PATH defines a class in code/Components/ that does not inherit Component. Is this intentional?"
            fi
        fi
    fi

    # Warning: missing IsProxy guard in OnUpdate/OnFixedUpdate (heuristic)
    if grep -qE 'protected override void On(Update|FixedUpdate)' "$FILE_PATH" 2>/dev/null; then
        if ! grep -qE 'if[[:space:]]*\([[:space:]]*IsProxy[[:space:]]*\)' "$FILE_PATH" 2>/dev/null; then
            WARNINGS="$WARNINGS\nSBOX: $FILE_PATH has OnUpdate/OnFixedUpdate but no IsProxy guard. If this Component is used in multiplayer, add: if ( IsProxy ) return;"
        fi
    fi

    # Warning: hardcoded numeric literals in gameplay methods (same pattern as validate-commit.sh)
    if grep -nE '(damage|health|speed|rate|chance|cost|duration)[[:space:]]*[:=][[:space:]]*[0-9]+' "$FILE_PATH" 2>/dev/null | grep -vE '\[Property\]|//'; then
        WARNINGS="$WARNINGS\nSBOX: $FILE_PATH may contain hardcoded gameplay values. Use [Property] attributes instead."
    fi

    # Warning: src/ path reference in code (wrong directory)
    if grep -nE '"src/' "$FILE_PATH" 2>/dev/null; then
        WARNINGS="$WARNINGS\nSBOX: $FILE_PATH references 'src/' in a string. s&box projects use 'code/' — check this is not a stale path."
    fi

fi

# ── .scene / .prefab file checks (JSON validity) ─────────────────────────────
if echo "$FILE_PATH" | grep -qE '\.(scene|prefab)$'; then
    PYTHON_CMD=""
    for cmd in python python3 py; do
        if command -v "$cmd" >/dev/null 2>&1; then
            PYTHON_CMD="$cmd"
            break
        fi
    done

    if [ -n "$PYTHON_CMD" ]; then
        if ! "$PYTHON_CMD" -m json.tool "$FILE_PATH" > /dev/null 2>&1; then
            WARNINGS="$WARNINGS\nSBOX: $FILE_PATH is not valid JSON. s&box scene/prefab files must be valid JSON."
        fi
    fi
fi

# ── .sbproj check ─────────────────────────────────────────────────────────────
if echo "$FILE_PATH" | grep -qE '\.sbproj$'; then
    PYTHON_CMD=""
    for cmd in python python3 py; do
        if command -v "$cmd" >/dev/null 2>&1; then
            PYTHON_CMD="$cmd"
            break
        fi
    done

    if [ -n "$PYTHON_CMD" ]; then
        if ! "$PYTHON_CMD" -m json.tool "$FILE_PATH" > /dev/null 2>&1; then
            echo "BLOCKED: $FILE_PATH (.sbproj) is not valid JSON. The project file must be valid JSON." >&2
            exit 2
        fi
    fi
fi

# Print warnings (non-blocking)
if [ -n "$WARNINGS" ]; then
    echo -e "=== s&box Validation Warnings ===$WARNINGS\n=================================" >&2
fi

exit 0
