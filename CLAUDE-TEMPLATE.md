# CLAUDE.md Template

> **Instructions:** Copy this template to your project root as `CLAUDE.md`. Replace all `[PLACEHOLDER]` sections with your project-specific details. Delete this instruction block when done.

---

# CLAUDE.md

This is the rulebook for Claude Code sessions working in this repository.

> **Note:** `CLAUDE-WORKFLOW.md` exists for human onboarding. Claude sessions should NOT read it - all necessary rules are here.

> **Required reading:** `CODE_INDEX.md` - Codebase navigation map. Read this to quickly find functions, files, and patterns.

## Goals

- [DESCRIBE YOUR PROJECT IN ONE LINE]
- [KEY TECHNICAL APPROACH - e.g., "Interactive web app", "CLI tool", "API service"]
- Built with Claude Code assistance following structured workflow
- Human role: review, define requirements, approve design decisions
- Claude role: plan, implement, test, document

## Hard Rules

- Never commit directly to `main`; always use feature branches
  - Branch naming: `feature/NAME`, `bugfix/NAME`, `refactor/NAME`, or `test/NAME`
  - Only exception: updating this CLAUDE.md file itself (with approval)
- Always run tests before proposing a PR
- [ADD PROJECT-SPECIFIC HARD RULES - e.g., "Never touch production database", "Never commit .env files"]
- Keep dependencies minimal (avoid bloat)
- Prioritize simplicity over features
- **Keep work units as small as logically possible** - Each unit should represent the smallest coherent change that can be independently tested and merged. Prefer many small PRs over few large ones.

## Coding Style & Stack

[REPLACE THIS ENTIRE SECTION WITH YOUR TECH STACK]

Example format:
```
- **Language:** [Language and version]
- **Framework:** [Primary framework]
- **Database:** [Database and ORM/driver]
- **Testing:** [Test framework]
- **Build/Run:** [Build tools, package manager]
- **Style:**
  - [Indentation preference]
  - [Naming conventions]
  - [Documentation requirements]
```

## Development Commands

[REPLACE WITH YOUR PROJECT'S COMMANDS]

```bash
# Setup
[INSTALLATION COMMAND]

# Run
[RUN COMMAND]

# Test
[TEST COMMAND]

# Build (if applicable)
[BUILD COMMAND]

# Lint (if applicable)
[LINT COMMAND]
```

## Document Hierarchy

This project uses a three-tier documentation system:

```
SPEC (Human writes)     →  PLAN (Planner creates)    →  FEATURES (Work units)
docs/features/FEATURE.md   plans/FEATURE.md             docs/features/FEATURE-units.md
What we want               How we'll build it           What to do next
```

| Document | Location | Owner | Purpose |
|----------|----------|-------|---------|
| **Spec** | `docs/features/FEATURE.md` | Human | Requirements, user stories, acceptance criteria |
| **Plan** | `plans/FEATURE.md` | Planner | Architecture, approach, milestones (living doc) |
| **Units** | `docs/features/FEATURE-units.md` | Planner → Implementer | Actionable micro-units with status |

**Key rules:**
- Planner creates BOTH plan and units files
- Plan file is updated after each milestone completes
- Units file tracks implementation progress
- Implementer works from units file, references plan file

## Work Units

A **Work Unit** is the smallest coherent, testable chunk of work:
- Results in ONE pull request
- Can be implemented, tested, and merged independently
- Has clear acceptance criteria

**Lifecycle:**
```
PENDING → IN_PROGRESS → IMPLEMENTED → VERIFIED → MERGED
```

**Skills update files automatically:**
- `/implement-step` updates units file status + plan milestones
- `/verify-ship` updates units file + plan on milestone complete

## Session Rules

**Each session = One role, One work unit**

| Role | Reads | Outputs |
|------|-------|---------|
| Planner | CLAUDE.md, CODE_INDEX.md, Spec | Plan + Units files |
| Implementer | CLAUDE.md, CODE_INDEX.md, Units file, Plan | Code + tests |
| Verifier | CLAUDE.md, Units file | PASS/FAIL report |
| Bug Fixer | CLAUDE.md, CODE_INDEX.md, Bug doc | Fixed code |

**At session end:**
1. Update units file with status
2. Update plan file if milestone complete
3. Tell user: "CLEAR CONTEXT, then run [next command]"

**TodoWrite:** Use for session-internal tracking only. Units file is the cross-session source of truth.

## Project Structure

[REPLACE WITH YOUR PROJECT STRUCTURE]

```
project-name/
├── CLAUDE.md              # This file (rulebook for Claude)
├── CLAUDE-WORKFLOW.md     # Human onboarding guide (Claude: do not read)
├── CODE_INDEX.md          # Codebase navigation map
├── README.md              # User documentation
│
├── src/                   # Source code
│   └── ...
│
├── test/                  # Tests
│   └── ...
│
├── plans/                 # Implementation plans (living docs)
│
└── docs/
    ├── features/          # Specs and units files
    └── bugs/              # Bug tracking
```

## Branching Strategy

| Role | Branch Prefix | Example |
|------|---------------|---------|
| Implementer | `feature/` | `feature/add-filter` |
| Bug Fixer | `bugfix/` | `bugfix/null-pointer` |
| Refactor | `refactor/` | `refactor/simplify-state` |

**Exceptions (direct commits to main):**
- Updating `CLAUDE.md` with explicit approval
- Updating units file status to MERGED after PR merge

## Testing Requirements

- [DESCRIBE YOUR TESTING PHILOSOPHY]
- [DATABASE/STATE ISOLATION REQUIREMENTS]
- [EDGE CASES TO ALWAYS TEST]
- Run full test suite before any PR
- [WHAT SHOULD NEVER BE COMMITTED - test databases, etc.]

## Data Model

[REPLACE WITH YOUR DATA MODEL OR DELETE IF NOT APPLICABLE]

Example format:
```
**Entity:** field1, field2 (constraints), field3

- Enums: value1, value2, value3
- Formats: ISO 8601, etc.
```

## [DOMAIN-SPECIFIC] Guidelines

[REPLACE THIS SECTION WITH GUIDELINES SPECIFIC TO YOUR DOMAIN]

Examples:
- For web apps: UI/UX guidelines, accessibility requirements
- For APIs: endpoint conventions, authentication patterns
- For CLIs: argument parsing, output formatting
- For libraries: public API design, backwards compatibility

## Implementation Notes

[ADD PROJECT-SPECIFIC GOTCHAS AND PATTERNS]

Examples:
- Cross-platform path handling
- Database connection patterns
- Error handling conventions
- Configuration management

## Lessons Learned

[START EMPTY - ADD ENTRIES AS YOU DISCOVER THEM]

### Template
```
### [DATE] - [Brief description]
**What happened:** [describe]
**Rule:** [new rule]
```

---

# Supporting Files

## CODE_INDEX.md Template

Create `CODE_INDEX.md` in your project root:

```markdown
# Code Index

Quick reference for navigating this codebase.

## Entry Points

| File | Purpose |
|------|---------|
| `src/main.[ext]` | Application entry point |
| `test/[runner]` | Test suite entry |

## Key Modules

| Module | Location | Responsibility |
|--------|----------|----------------|
| [Name] | `src/[path]` | [What it does] |

## Common Patterns

### [Pattern Name]
```[language]
// Example code showing the pattern
```

## Where to Find Things

| If you need... | Look in... |
|----------------|------------|
| [Feature] | `src/[path]` |
| [Tests for X] | `test/[path]` |
```

## CLAUDE-WORKFLOW.md Template

Create `CLAUDE-WORKFLOW.md` for human onboarding (Claude should not read this):

```markdown
# Claude Code Workflow Guide

Human-readable guide for working with Claude on this project.

## Quick Start

1. Write a spec in `docs/features/FEATURE.md`
2. Run `/plan-feature docs/features/FEATURE.md`
3. Review the plan in `plans/FEATURE.md`
4. Run `/implement-step docs/features/FEATURE-units.md`
5. Review PR, merge
6. Repeat step 4-5 until complete
7. Run `/verify-ship docs/features/FEATURE-units.md`

## Roles Explained

[Detailed explanation of each role for humans]

## Tips

[Human-specific tips for working with this workflow]
```

## Feature Spec Template

Create in `docs/features/FEATURE.md`:

```markdown
# Feature: [Name]

## Summary
[One paragraph description]

## User Stories
- As a [user], I want [feature] so that [benefit]

## Requirements
- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Out of Scope
- [What this feature does NOT include]

## Open Questions
- [Questions needing answers before planning]
```

## Plan Template

Planner creates in `plans/FEATURE.md`:

```markdown
# Plan: [Feature Name]

**Spec:** `docs/features/FEATURE.md`
**Units:** `docs/features/FEATURE-units.md`
**Status:** Planning | In Progress | Complete

## Overview
[How this feature will be built]

## Architecture
[Key design decisions]

## Milestones

### Milestone 1: [Name]
- **Status:** Not Started | In Progress | Complete
- **Units:** 1.1, 1.2, 1.3
- [Description]

### Milestone 2: [Name]
...

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk] | [How to handle] |

## Updates
- [DATE]: [What changed]
```

## Units File Template

Planner creates in `docs/features/FEATURE-units.md`:

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
**Branch:** `feature/[name]`
**Depends on:** None

**Task:**
[Clear description of what to implement]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Files to modify:**
- `src/[file]` - [what to change]

---

### Unit 1.2: [Title]
...
```

## Bug Documentation Template

Create in `docs/bugs/BUG-NAME.md`:

```markdown
# Bug: [Title]

**Status:** Open | In Progress | Fixed
**Severity:** Critical | High | Medium | Low
**Found:** [DATE]
**Fixed:** [DATE or N/A]

## Description
[What's wrong]

## Steps to Reproduce
1. Step 1
2. Step 2
3. Observe [bug]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Root Cause
[Once identified]

## Fix
[Once implemented]
```
