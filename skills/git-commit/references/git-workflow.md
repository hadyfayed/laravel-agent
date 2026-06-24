# Git workflow automation reference

Knowledge folded from the retired `laravel-git` agent. Use alongside the
`git-commit`, `git-pr`, and `git-release` skills for branch strategy, commit
message generation, and review-system integration.

**Philosophy: "Clean history, atomic commits, meaningful messages."**

## Workflow architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GIT WORKFLOW AUTOMATION                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐              │
│  │   COMMIT    │   │   BRANCH    │   │   RELEASE   │              │
│  │   WORKFLOW  │   │   WORKFLOW  │   │   WORKFLOW  │              │
│  ├─────────────┤   ├─────────────┤   ├─────────────┤              │
│  │ • Stage     │   │ • Create    │   │ • Changelog │              │
│  │ • Review    │   │ • Switch    │   │ • Version   │              │
│  │ • Message   │   │ • Merge     │   │ • Tag       │              │
│  │ • Push      │   │ • Delete    │   │ • Publish   │              │
│  └─────────────┘   └─────────────┘   └─────────────┘              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Commit conventions

### Conventional Commits Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(auth): add 2FA support` |
| `fix` | Bug fix | `fix(invoice): correct tax calculation` |
| `refactor` | Code refactoring | `refactor(orders): extract payment logic` |
| `docs` | Documentation | `docs(api): update endpoint descriptions` |
| `test` | Adding tests | `test(user): add registration tests` |
| `chore` | Maintenance | `chore(deps): update Laravel to 11.x` |
| `style` | Code style | `style: apply Laravel Pint formatting` |
| `perf` | Performance | `perf(queries): add eager loading` |
| `ci` | CI/CD changes | `ci: add GitHub Actions workflow` |
| `build` | Build system | `build: configure Vite for production` |

### Scopes (Laravel-specific)
- `auth`, `api`, `ui`, `db`, `queue`, `mail`, `cache`
- Feature names: `invoice`, `order`, `user`, `product`
- Module names: `billing`, `inventory`, `crm`

### Breaking Changes
```
feat(api)!: change response format

BREAKING CHANGE: API responses now use JSON:API format.
Clients must update their parsers.

Migration guide: docs/api-v2-migration.md
```

## Smart Commit Message Generation

Analyze staged changes to generate meaningful commit messages:

```bash
# Get staged files
git diff --cached --name-only

# Get diff stats
git diff --cached --stat

# Analyze changes
git diff --cached
```

### Message Generation Rules

1. **Single file change:**
   ```
   <type>(<file-scope>): <action> <subject>

   Example: fix(UserController): handle null email validation
   ```

2. **Multiple files, single feature:**
   ```
   <type>(<feature>): <action>

   - Detail 1
   - Detail 2

   Example:
   feat(invoice): add PDF export functionality

   - Add InvoicePdfExporter service
   - Add export button to invoice view
   - Add PDF download route
   ```

3. **Multiple features:**
   ```
   Consider splitting into multiple commits!

   If must be single commit:
   chore: multiple improvements

   - feat(auth): add remember me option
   - fix(dashboard): correct chart rendering
   - docs(readme): update installation steps
   ```

## Branch strategy

### GitFlow for Laravel

```
main ─────────────────────────────────────────────────► (production)
  │
  └─ develop ──────────────────────────────────────────► (staging)
       │
       ├─ feature/invoice-pdf ─────────┐
       │                               │
       ├─ feature/user-2fa ────────────┤
       │                               │
       └───────────────────────────────┴────────────────►
```

### Branch Naming

```
<type>/<ticket>-<description>

Types:
- feature/  - New features
- fix/      - Bug fixes
- hotfix/   - Production fixes
- refactor/ - Code improvements
- docs/     - Documentation
- test/     - Test additions

Examples:
- feature/INV-123-pdf-export
- fix/INV-456-tax-calculation
- hotfix/critical-auth-bypass
- refactor/extract-payment-service
```

## Command workflows

### /git:commit — Smart commit with review integration

```bash
# Process:
# 1. Run /review:staged for security check
# 2. Generate commit message from changes
# 3. Present message for approval/edit
# 4. Create commit with co-author

# Example output:
## Staged Changes Analysis

Files: 3 changed, 45 insertions, 12 deletions

### Security Check: PASSED
No issues found.

### Suggested Commit Message:
```
feat(invoice): add PDF export functionality

- Add InvoicePdfExporter service using DomPDF
- Add export button to invoice show view
- Add GET /invoices/{id}/pdf route

Closes #123
```

[Approve] [Edit] [Cancel]
```

### /git:branch — Smart branch creation

```bash
# Process:
# 1. Determine branch type from description
# 2. Generate branch name
# 3. Create and switch to branch

# Example:
/git:branch "Add PDF export for invoices"

# Output:
Creating branch: feature/add-pdf-export-invoices
From: develop
```

### /git:pr — Create pull request with generated description

```bash
# Process:
# 1. Get all commits since branch point
# 2. Run full review
# 3. Generate PR description
# 4. Create PR via gh cli

# Example PR template:
## Summary
<Generated from commits and review>

## Changes
- <List of changes from commits>

## Review Results
- Security: PASSED
- Quality: 2 suggestions
- Tests: PASSED (85% coverage)

## Testing
- [ ] Manual testing completed
- [ ] All tests pass
- [ ] No console errors

## Screenshots
<If UI changes detected>
```

### /git:release — Create release with changelog

```bash
# Process:
# 1. Determine version bump (major/minor/patch)
# 2. Generate changelog from commits
# 3. Create release tag
# 4. Push to remote

# Example:
/git:release minor

# Output:
## Release v1.2.0

### Features
- feat(invoice): add PDF export (#123)
- feat(auth): add 2FA support (#124)

### Bug Fixes
- fix(dashboard): correct chart rendering (#125)

### Breaking Changes
None

[Create Release] [Edit] [Cancel]
```

## Integration with review system

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run staged file review
result=$(claude /review:staged --fail-on=critical 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "Pre-commit check failed:"
    echo "$result"
    exit 1
fi

echo "Pre-commit check passed"
exit 0
```

### Pre-Push Hook

```bash
#!/bin/bash
# .git/hooks/pre-push

# Get commits being pushed
commits=$(git log @{u}.. --oneline)

if [ -z "$commits" ]; then
    exit 0
fi

# Run review on changed files
changed_files=$(git diff --name-only @{u}..)
result=$(claude /review:audit "$changed_files" --score-only 2>&1)

if [ "$result" -lt 70 ]; then
    echo "Code quality score too low: $result"
    echo "Run 'claude /review:audit' for details"
    exit 1
fi

exit 0
```

## Guardrails

- **NEVER** force push to main/master
- **NEVER** commit sensitive data (secrets, credentials)
- **NEVER** create commits without reviewing staged changes
- **ALWAYS** run security check before commit
- **ALWAYS** use conventional commit format
- **ALWAYS** include ticket reference when available
