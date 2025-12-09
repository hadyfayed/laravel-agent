---
description: "Smart commit with security review and message generation"
allowed-tools: Task, Read, Glob, Grep, Bash
---

# /git:commit - Smart Commit

Create commits with automatic security review and intelligent message generation.

## Input
$ARGUMENTS = `[--skip-review] [--amend] [message]`

Examples:
- `/git:commit` - Review, generate message, commit
- `/git:commit "feat: add feature"` - Use provided message
- `/git:commit --skip-review` - Skip security review
- `/git:commit --amend` - Amend previous commit

## Process

### 1. Check Staged Changes

```bash
# Get staged files
git diff --cached --name-only

# Exit if nothing staged
if [ -z "$(git diff --cached --name-only)" ]; then
    echo "Nothing staged for commit"
    exit 1
fi
```

### 2. Security Review (unless --skip-review)

Run `/review:staged` to check for:
- Security vulnerabilities
- Debug statements (dd, dump)
- Hardcoded secrets
- Critical quality issues

```markdown
## Security Review Results

Status: PASSED / FAILED

Issues:
- [List any issues found]

[Continue] [Fix Issues] [Skip Review]
```

### 3. Analyze Changes

```bash
# Get file changes
git diff --cached --stat

# Categorize changes
# - Feature files (Controllers, Models, Services)
# - Test files
# - Config files
# - Migration files
# - View files
```

### 4. Generate Commit Message

Based on analysis:

**Single File:**
```
<type>(<scope>): <action based on diff>
```

**Multiple Files, Same Feature:**
```
<type>(<feature>): <summary>

- Change 1
- Change 2
```

**Multiple Features:**
```
Suggest splitting commits or:

chore: multiple changes

- <change 1>
- <change 2>
```

### 5. Present for Approval

```markdown
## Commit Preview

### Staged Files (3)
- app/Services/InvoiceService.php (+45 -12)
- app/Http/Controllers/InvoiceController.php (+23 -5)
- tests/Feature/InvoiceTest.php (+67 -0)

### Generated Message
```
feat(invoice): add PDF export functionality

- Add InvoicePdfExporter service with DomPDF
- Add export endpoint to InvoiceController
- Add feature tests for PDF generation

Closes #123
```

### Security: PASSED

[Commit] [Edit Message] [Cancel]
```

### 6. Create Commit

```bash
git commit -m "$(cat <<'EOF'
feat(invoice): add PDF export functionality

- Add InvoicePdfExporter service with DomPDF
- Add export endpoint to InvoiceController
- Add feature tests for PDF generation

Closes #123
EOF
)"
```

## Message Templates

### Feature
```
feat(<scope>): <add|implement> <feature>

- <detail 1>
- <detail 2>

Closes #<ticket>
```

### Bug Fix
```
fix(<scope>): <correct|resolve|handle> <issue>

<What was wrong>
<What was fixed>

Fixes #<ticket>
```

### Refactor
```
refactor(<scope>): <extract|simplify|reorganize> <target>

- <change 1>
- <change 2>

No functional changes.
```

### Breaking Change
```
feat(<scope>)!: <change>

BREAKING CHANGE: <description of breaking change>

Migration: <steps to migrate>
```

## Exit Codes

- `0` - Commit successful
- `1` - Nothing to commit
- `2` - Review failed (critical issues)
- `3` - User cancelled
