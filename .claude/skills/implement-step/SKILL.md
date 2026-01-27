---
description: Implement a single work unit from the units file
argument-hint: docs/features/FEATURE-units.md [unit-number]
---

# Skill: Implement Step

Implement a single work unit from the units file.

## Usage

```
/implement-step docs/features/FEATURE-units.md [unit-number]
```

If unit-number is omitted, implement the next PENDING unit.

## Instructions

You are acting as the **Implementer** role.

### Step 1: Read Required Files

1. Read `CLAUDE.md` (project rules)
2. Read `CODE_INDEX.md` (codebase navigation)
3. Read the units file provided as argument
4. Read the corresponding plan file (linked in units file header)

### Step 2: Identify the Unit to Implement

- If unit number provided, use that unit
- Otherwise, find the first unit with status `PENDING` whose dependencies are all `MERGED`
- If no eligible units, inform the user

### Step 3: Update Unit Status

Update the units file to mark the unit as `IN_PROGRESS`.

### Step 4: Create Feature Branch

```bash
git checkout -b feature/[branch-name-from-unit]
```

### Step 5: Implement the Unit

Follow the unit's task description and acceptance criteria:

1. Write the code changes
2. Write tests for the new functionality
3. Ensure all tests pass
4. Follow coding style from CLAUDE.md

### Step 6: Run Tests

Use the Julia REPL MCP (not bash):
```julia
# In MCP REPL:
using Pkg; Pkg.test()
```

All tests must pass before proceeding.

### Step 7: Update Unit Status

Update the units file:
- Change status to `IMPLEMENTED`
- Check off completed acceptance criteria

### Step 8: Check if Milestone Complete

If all units in the current milestone are `IMPLEMENTED` or beyond:
- Update the plan file's milestone status to `In Progress`

### Step 9: Commit Changes

Stage and commit all changes with a descriptive message:

```bash
git add [specific files]
git commit -m "$(cat <<'EOF'
[Brief description of what was implemented]

Unit: [unit number] - [unit title]
Feature: [feature name]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 10: Report to User

Tell the user:

1. What was implemented
2. What tests were added/modified
3. Any issues encountered
4. **"Review the changes, then CLEAR CONTEXT and run `/verify-ship docs/features/FEATURE-units.md [unit-number]`"**

## Key Rules

- ONE unit per session - do not implement multiple units
- Always create a feature branch (never commit to main)
- Run tests before marking as IMPLEMENTED
- Update both the units file AND the code
- Keep changes focused on the unit's scope only
- **Use Julia REPL MCP** - NEVER use `julia` in bash (see CLAUDE.md "Julia REPL" section)
