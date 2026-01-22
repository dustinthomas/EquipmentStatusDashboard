---
description: Verify an implemented unit and create a pull request
argument-hint: docs/features/FEATURE-units.md [unit-number]
---

# Skill: Verify and Ship

Verify an implemented unit and prepare it for merge.

## Usage

```
/verify-ship docs/features/FEATURE-units.md [unit-number]
```

If unit-number is omitted, verify the first `IMPLEMENTED` unit.

## Instructions

You are acting as the **Verifier** role.

### Step 1: Read Required Files

1. Read `CLAUDE.md` (project rules)
2. Read the units file provided as argument

### Step 2: Identify the Unit to Verify

- If unit number provided, use that unit
- Otherwise, find the first unit with status `IMPLEMENTED`
- If no eligible units, inform the user

### Step 3: Checkout the Feature Branch

```bash
git checkout [branch-name-from-unit]
```

### Step 4: Run Verification Checks

#### 4a. Run All Tests
```bash
julia --project=. -e "using Pkg; Pkg.test()"
```

#### 4b. Review Acceptance Criteria
Check each criterion in the unit:
- Read the relevant code
- Verify the criterion is met
- Note any failures

#### 4c. Check Code Quality
- Follows coding style from CLAUDE.md
- No obvious bugs or security issues
- Tests cover the new functionality

### Step 5: Determine Result

**If ALL checks pass:**
1. Update unit status to `VERIFIED`
2. Proceed to Step 6

**If ANY check fails:**
1. Keep unit status as `IMPLEMENTED`
2. Document what failed in the units file as a comment
3. Tell user: **"CLEAR CONTEXT, then run `/implement-step` to fix: [issues]"**
4. Stop here (do not proceed to Step 6)

### Step 6: Create Pull Request

```bash
gh pr create --title "[Unit title]" --body "$(cat <<'EOF'
## Summary
- [What this unit implements]

## Unit Reference
- Feature: [feature name]
- Unit: [unit number] - [unit title]
- Units file: `docs/features/FEATURE-units.md`

## Test plan
- [How to test this change]

---
Generated with [Claude Code](https://claude.ai/claude-code)
EOF
)"
```

### Step 7: Update Files

Update the units file:
- Status: `VERIFIED`
- Add PR link

Check if milestone is complete (all units `VERIFIED` or `MERGED`):
- If yes, update plan file milestone status to `Complete`

### Step 8: Report to User

**PASS Report:**
```
VERIFICATION PASSED

Unit: [number] - [title]
PR: [link]

All acceptance criteria met.
All tests pass.

Next steps:
1. Review and merge the PR
2. After merge, update unit status to MERGED
3. CLEAR CONTEXT, then run `/implement-step docs/features/FEATURE-units.md` for next unit
```

**FAIL Report:**
```
VERIFICATION FAILED

Unit: [number] - [title]

Issues found:
- [Issue 1]
- [Issue 2]

CLEAR CONTEXT, then run `/implement-step docs/features/FEATURE-units.md [unit-number]` to fix.
```

## Key Rules

- Be thorough - verify ALL acceptance criteria
- Do not skip tests
- Document failures clearly so implementer can fix
- Only create PR if verification passes
- Update milestone status when all units complete
