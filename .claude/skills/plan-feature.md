# Skill: Plan Feature

Plan a feature from a spec file, creating both the plan and units files.

## Usage

```
/plan-feature docs/features/FEATURE.md
```

## Instructions

You are acting as the **Planner** role.

### Step 1: Read Required Files

1. Read `CLAUDE.md` (project rules)
2. Read `CODE_INDEX.md` (codebase navigation)
3. Read the spec file provided as argument

### Step 2: Analyze the Spec

- Understand the requirements and acceptance criteria
- Identify any open questions that need clarification
- If questions exist, ask the user before proceeding

### Step 3: Create the Plan File

Create `plans/FEATURE.md` with this structure:

```markdown
# Plan: [Feature Name]

**Spec:** `docs/features/FEATURE.md`
**Units:** `docs/features/FEATURE-units.md`
**Status:** Planning

## Overview
[How this feature will be built]

## Architecture
[Key design decisions, patterns to use, files to create/modify]

## Milestones

### Milestone 1: [Name]
- **Status:** Not Started
- **Units:** 1.1, 1.2, ...
- [Description of what this milestone achieves]

### Milestone 2: [Name]
...

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk] | [How to handle] |

## Updates
- [DATE]: Initial plan created
```

### Step 4: Create the Units File

Create `docs/features/FEATURE-units.md` with this structure:

```markdown
# Work Units: [Feature Name]

**Plan:** `plans/FEATURE.md`
**Spec:** `docs/features/FEATURE.md`

## Status Legend
- PENDING: Not started
- IN_PROGRESS: Being worked on
- IMPLEMENTED: Code complete, needs verification
- VERIFIED: Tests pass, ready for merge
- MERGED: Complete

## Milestone 1: [Name]

### Unit 1.1: [Title]
**Status:** PENDING
**Branch:** `feature/[descriptive-name]`
**Depends on:** None

**Task:**
[Clear, specific description of what to implement]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Files to modify:**
- `path/to/file` - [what to change]

---

### Unit 1.2: [Title]
...
```

### Step 5: Report to User

After creating both files, tell the user:

1. Summary of the plan (milestones, number of units)
2. Any risks or concerns identified
3. **"CLEAR CONTEXT, then run `/implement-step docs/features/FEATURE-units.md` to start Unit 1.1"**

## Key Rules

- Keep units as small as possible (one PR each)
- Each unit must be independently testable
- Units within a milestone can have dependencies
- Cross-milestone dependencies should be avoided
- Follow the project's coding style from CLAUDE.md
