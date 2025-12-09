---
description: "Create pull request with auto-generated description and review"
allowed-tools: Task, Read, Glob, Grep, Bash
---

# /git:pr - Create Pull Request

Create a pull request with automatically generated description from commits and code review.

## Input
$ARGUMENTS = `[--base=branch] [--draft] [--no-review]`

Examples:
- `/git:pr` - Create PR to develop
- `/git:pr --base=main` - Create PR to main
- `/git:pr --draft` - Create draft PR
- `/git:pr --no-review` - Skip code review

## Process

### 1. Validate Branch State

```bash
# Check current branch
current_branch=$(git branch --show-current)

# Ensure not on main/develop
if [[ "$current_branch" == "main" || "$current_branch" == "develop" ]]; then
    echo "Cannot create PR from $current_branch"
    exit 1
fi

# Check for unpushed commits
unpushed=$(git log @{u}.. --oneline 2>/dev/null)

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes detected. Commit or stash first."
    exit 1
fi
```

### 2. Gather Commit History

```bash
# Get base branch (default: develop)
base_branch=${BASE:-develop}

# Get all commits since branching
git log $base_branch..HEAD --oneline

# Get detailed changes
git log $base_branch..HEAD --pretty=format:"- %s" --no-merges
```

### 3. Run Code Review (unless --no-review)

```
/review:pr $current_branch

Results used for PR description.
```

### 4. Generate PR Description

```markdown
## Summary

<Generated from commit messages and branch name>

### What does this PR do?
- <Feature/fix description>

### Why is this change needed?
- <Business context if available from commits>

## Changes

<From git log>

- feat(invoice): add PDF export service
- feat(invoice): add export endpoint
- test(invoice): add PDF generation tests

## Files Changed

<From git diff --stat>

| File | Changes |
|------|---------|
| app/Services/InvoiceService.php | +45 -12 |
| app/Http/Controllers/InvoiceController.php | +23 -5 |
| tests/Feature/InvoiceTest.php | +67 -0 |

## Code Review

### Security
- Status: PASSED
- Issues: None

### Quality
- Status: 2 suggestions
- Suggestions:
  - Consider adding index to `invoices.user_id`
  - Extract PDF configuration to config file

### Tests
- Coverage: 85%
- New tests: 3

## Testing

### How to test
1. <Generated steps based on changes>
2. <Or manual steps if complex>

### Checklist
- [ ] Tests pass locally
- [ ] Manual testing completed
- [ ] Documentation updated (if needed)

## Screenshots

<If view files changed, prompt for screenshots>

## Related

- Closes #<ticket if found in commits>
- Related to #<other tickets>
```

### 5. Create PR

```bash
# Push branch if needed
if [ -n "$(git log @{u}.. --oneline 2>/dev/null)" ]; then
    git push -u origin $current_branch
fi

# Create PR
gh pr create \
    --base "$base_branch" \
    --title "<generated title>" \
    --body "$(cat pr-description.md)" \
    ${DRAFT:+--draft}
```

### 6. Post-Create Actions

```bash
# Add reviewers (from CODEOWNERS or config)
gh pr edit --add-reviewer <reviewers>

# Add labels based on changes
gh pr edit --add-label "feature" # or "bug", "refactor", etc.

# Link to project board if configured
gh pr edit --add-project "Sprint Board"
```

## Output

```markdown
## Pull Request Created

**URL:** https://github.com/org/repo/pull/123

**Title:** feat(invoice): add PDF export functionality

**Base:** develop ← feature/invoice-pdf-export

**Review Status:**
- Security: PASSED
- Quality: 2 suggestions (non-blocking)
- Tests: PASSED

**Next Steps:**
1. Address review suggestions (optional)
2. Wait for CI checks
3. Request team review
4. Merge when approved
```

## Templates

### Feature PR
```markdown
## Feature: <Name>

### What
<Description>

### Why
<Business value>

### How
<Technical approach>
```

### Bug Fix PR
```markdown
## Bug Fix: <Issue>

### Problem
<What was broken>

### Root Cause
<Why it was broken>

### Solution
<How it's fixed>

### Verification
<How to verify fix>
```

### Hotfix PR
```markdown
## HOTFIX: <Critical Issue>

### Severity
CRITICAL / HIGH

### Impact
<What's affected>

### Fix
<What's being done>

### Rollback Plan
<If fix fails>
```
