---
name: git-pr
description: Create a well-formed pull request (title/body/labels) from the current branch via gh; manual invoke only.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *) Read
argument-hint: "[--base=branch] [--draft]"
---

## Current branch state

!`git branch --show-current`
!`git log origin/..HEAD --oneline 2>/dev/null || git log --oneline -5`
!`git diff origin/HEAD...HEAD --stat 2>/dev/null || git diff HEAD~3...HEAD --stat`

## Task

Create a pull request from the current branch to the base branch (default: main).

## Input

- **--base=branch:** Target branch (default: `main`)
- **--draft:** Create as draft PR (blocks merge until marked ready)

## Validation

1. **Check current branch is not main/develop:**
   ```bash
   current=$(git branch --show-current)
   if [[ "$current" == "main" || "$current" == "develop" ]]; then
       echo "Cannot create PR from $current"
       exit 1
   fi
   ```

2. **Verify no uncommitted changes:**
   ```bash
   if [ -n "$(git status --porcelain)" ]; then
       echo "Uncommitted changes detected. Commit or stash first."
       exit 1
   fi
   ```

## Steps

1. **Push branch to remote (if needed):**
   ```bash
   if git rev-parse --verify origin/$(git branch --show-current) >/dev/null 2>&1; then
       git push
   else
       git push -u origin $(git branch --show-current)
   fi
   ```

2. **Gather commit messages for PR title/body:**
   ```bash
   base_branch=${BASE:-main}
   commits=$(git log $base_branch..HEAD --pretty=format:"%s" --no-merges | head -1)
   ```

3. **Create PR via gh:**
   ```bash
   gh pr create \
       --base "$base_branch" \
       --title "$commits" \
       ${DRAFT:+--draft}
   ```

4. **Show final status:**
   ```bash
   gh pr view --json url,title,state
   ```

## PR template guidance

If gh prompts for body text, follow this format:

```markdown
## Summary
<One-sentence description of what this PR does>

## Changes
- <Commit 1 summary>
- <Commit 2 summary>

## Testing
<How to test / verification steps>

## Related
Closes #<ticket> (if applicable)
```

## Security checks (pre-submit)

Before confirming PR creation, verify staged files do NOT contain:
- Hardcoded credentials, API keys, or secrets
- Debug helpers (dd(, dump(, console.log)
- TODO comments that block merge

If any found, pause and do NOT create PR until issues are resolved.
