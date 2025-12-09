---
description: "Create release with changelog generation"
allowed-tools: Task, Read, Glob, Grep, Bash, Write
---

# /git:release - Create Release

Create a new release with automatic changelog generation from conventional commits.

## Input
$ARGUMENTS = `<version|major|minor|patch> [--dry-run] [--no-tag]`

Examples:
- `/git:release patch` - Bump patch version (1.0.0 → 1.0.1)
- `/git:release minor` - Bump minor version (1.0.0 → 1.1.0)
- `/git:release major` - Bump major version (1.0.0 → 2.0.0)
- `/git:release 2.0.0` - Set specific version
- `/git:release minor --dry-run` - Preview without creating

## Process

### 1. Determine Current Version

```bash
# From git tags
current=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")

# Or from composer.json
current=$(jq -r '.version // "0.0.0"' composer.json)
```

### 2. Calculate New Version

```bash
# Parse current version
IFS='.' read -r major minor patch <<< "${current#v}"

case "$bump" in
    major) new="$((major + 1)).0.0" ;;
    minor) new="$major.$((minor + 1)).0" ;;
    patch) new="$major.$minor.$((patch + 1))" ;;
    *) new="$bump" ;; # Specific version
esac
```

### 3. Gather Commits Since Last Release

```bash
# Get commits since last tag
if [ -n "$current" ]; then
    commits=$(git log $current..HEAD --pretty=format:"%s|%h|%an" --no-merges)
else
    commits=$(git log --pretty=format:"%s|%h|%an" --no-merges)
fi
```

### 4. Generate Changelog

Parse conventional commits and categorize:

```markdown
# Changelog

## [1.1.0] - 2024-01-15

### Features
- **invoice:** Add PDF export functionality (#123) - @developer
- **auth:** Add two-factor authentication (#124) - @developer

### Bug Fixes
- **dashboard:** Fix chart rendering on mobile (#125) - @developer
- **api:** Handle null response from payment gateway (#126) - @developer

### Performance
- **queries:** Add database indexes for user lookups (#127) - @developer

### Breaking Changes
- **api:** Response format changed to JSON:API (#128)
  - Migration guide: docs/api-v2.md

### Other Changes
- **deps:** Update Laravel to 11.x
- **ci:** Add GitHub Actions workflow
- **docs:** Update API documentation

### Contributors
- @developer1 (5 commits)
- @developer2 (3 commits)
```

### 5. Update Version Files

```bash
# Update composer.json
jq ".version = \"$new\"" composer.json > tmp.json && mv tmp.json composer.json

# Update package.json (if exists)
if [ -f package.json ]; then
    jq ".version = \"$new\"" package.json > tmp.json && mv tmp.json package.json
fi

# Update config/app.php version constant (if used)
sed -i "s/'version' => '.*'/'version' => '$new'/" config/app.php 2>/dev/null || true
```

### 6. Create Release Commit

```bash
git add -A
git commit -m "chore(release): $new

$(cat CHANGELOG.md | head -50)
"
```

### 7. Create Tag

```bash
# Create annotated tag
git tag -a "v$new" -m "Release v$new

## Highlights
<Top 3 changes>

## Full Changelog
See CHANGELOG.md
"
```

### 8. Push Release

```bash
# Push commits and tags
git push origin main --follow-tags

# Create GitHub release
gh release create "v$new" \
    --title "v$new" \
    --notes-file CHANGELOG.md
```

## Output

```markdown
## Release Created

**Version:** v1.1.0
**Date:** 2024-01-15

### Summary
- Features: 2
- Bug Fixes: 2
- Breaking Changes: 1

### Highlights
1. PDF export for invoices
2. Two-factor authentication
3. Performance improvements

### Files Updated
- CHANGELOG.md
- composer.json
- package.json

### Commands Run
```bash
git add -A
git commit -m "chore(release): 1.1.0"
git tag -a v1.1.0
git push origin main --follow-tags
gh release create v1.1.0
```

### Next Steps
1. Verify release on GitHub
2. Deploy to production
3. Announce release
```

## Changelog Format (Keep a Changelog)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security

## [1.1.0] - 2024-01-15

### Added
- PDF export for invoices (#123)
- Two-factor authentication (#124)

### Fixed
- Dashboard chart rendering on mobile (#125)

### Security
- Update dependencies to patch CVE-2024-XXXX

## [1.0.0] - 2024-01-01

### Added
- Initial release
```

## Semantic Versioning Rules

| Change Type | Version Bump | When |
|-------------|--------------|------|
| Breaking change | Major | API incompatible changes |
| New feature | Minor | Backwards-compatible additions |
| Bug fix | Patch | Backwards-compatible fixes |
| Deprecation | Minor | Feature deprecated (still works) |
| Security fix | Patch | Security vulnerability fixed |

## Pre-release Versions

```bash
# Beta
/git:release 1.1.0-beta.1

# Release candidate
/git:release 1.1.0-rc.1

# Alpha
/git:release 1.1.0-alpha.1
```
