---
description: "Show current design pattern usage and limits"
allowed-tools: Read, Bash, Glob, Grep
---

# /patterns - Pattern Registry Status

Display current design pattern usage in the project.

## Process

1. **Read Pattern Registry**

```bash
cat .ai/patterns/registry.json 2>/dev/null || echo '{"patterns": [], "limit": 5}'
```

2. **Scan Codebase for Patterns**

```bash
echo "=== Pattern Detection ==="

echo -n "Repository: "
find app -name "*Repository.php" 2>/dev/null | wc -l | tr -d ' '

echo -n "Actions: "
find app/Actions -name "*Action.php" 2>/dev/null | wc -l | tr -d ' '

echo -n "Services: "
find app/Services -name "*Service.php" 2>/dev/null | wc -l | tr -d ' '

echo -n "DTOs: "
grep -r "readonly class.*Data" app/ --include="*.php" -l 2>/dev/null | wc -l | tr -d ' '

echo -n "Strategies: "
grep -r "implements.*Strategy" app/ --include="*.php" -l 2>/dev/null | wc -l | tr -d ' '

echo -n "Events: "
find app/Events -name "*.php" 2>/dev/null | wc -l | tr -d ' '
```

3. **Output Report**

```markdown
## Pattern Registry

### Usage: X/5 patterns

| Pattern | Count | Location |
|---------|-------|----------|
| ... | ... | ... |

### Available Slots: Y

### Available Patterns
Repository, DTO, Strategy, Action, Factory, Pipeline, Observer, QueryObject, Presenter, Builder
```
