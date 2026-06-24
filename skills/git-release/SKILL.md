---
name: git-release
description: Cut a release — version bump, changelog, tag, GitHub release; manual invoke only.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *) Read Write Edit
argument-hint: "<version|major|minor|patch> [--dry-run]"
---

## Current version state

!`git describe --tags --abbrev=0 2>/dev/null || echo "No tags found. First release."`
!`git log --oneline -10`

## Task

Create a release: bump version, generate changelog, tag, and push to GitHub.

## Input

- **version:** Bump type (`major`, `minor`, `patch`) or explicit version (e.g., `2.0.0`)
- **--dry-run:** Show what would be changed without committing

## Steps

1. **Determine current version:**
   ```bash
   current=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
   current="${current#v}" # Remove 'v' prefix if present
   ```

2. **Calculate new version:**
   ```bash
   IFS='.' read -r major minor patch <<< "$current"
   case "$bump" in
       major) new="$((major + 1)).0.0" ;;
       minor) new="$major.$((minor + 1)).0" ;;
       patch) new="$major.$minor.$((patch + 1))" ;;
       *) new="$bump" ;;
   esac
   ```

3. **Gather commits since last release:**
   ```bash
   if [ "$current" != "0.0.0" ]; then
       commits=$(git log "v$current"..HEAD --pretty=format:"%s|%h|%an" --no-merges)
   else
       commits=$(git log --pretty=format:"%s|%h|%an" --no-merges)
   fi
   ```

4. **Generate changelog** from conventional commits:
   - Parse feat: → Features
   - Parse fix: → Bug Fixes
   - Parse perf: → Performance
   - Parse breaking change → Breaking Changes
   - Write to CHANGELOG.md or append [unreleased] section

5. **Update version files:**
   ```bash
   # composer.json
   jq ".version = \"$new\"" composer.json > tmp.json && mv tmp.json composer.json
   
   # package.json (if exists)
   [ -f package.json ] && jq ".version = \"$new\"" package.json > tmp.json && mv tmp.json package.json
   ```

6. **Create release commit:**
   ```bash
   git add -A
   git commit -m "chore(release): $new

   $(head -20 CHANGELOG.md)"
   ```

7. **Create annotated tag:**
   ```bash
   git tag -a "v$new" -m "Release v$new

   See CHANGELOG.md for details"
   ```

8. **Push commits and tags:**
   ```bash
   git push origin $(git branch --show-current) --follow-tags
   gh release create "v$new" --title "v$new" --notes-file CHANGELOG.md
   ```

## Changelog format (Keep a Changelog)

```markdown
# Changelog

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

### Fixed
- Dashboard chart rendering (#125)

### Security
- Update dependencies for CVE patch
```

## Semantic Versioning

| Change | Bump | When |
|--------|------|------|
| Breaking change | Major | API incompatible |
| New feature | Minor | Backwards-compatible |
| Bug fix | Patch | Backwards-compatible |
| Deprecation | Minor | Still works |
| Security | Patch | Vulnerability fixed |

## Pre-release versions

```bash
# Beta
/git:release 1.1.0-beta.1

# Release candidate
/git:release 1.1.0-rc.1
```

## Verification

Before pushing, verify:

```bash
git log --oneline -1               # Verify release commit
git tag --list | tail -1           # Verify tag created
cat CHANGELOG.md | head -10         # Verify changelog updated
```
