---
name: plugin-publish
description: Publish a Claude Code plugin to marketplace — validate, bump version, tag, release; when releasing a plugin.
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(claude *) Read Write Edit
argument-hint: "[version] [--channel=marketplace|github|both]"
---

## Task

Publish the plugin at the current working directory (must contain `.claude-plugin/plugin.json`).

## Input

Parse `$ARGUMENTS`:
- `[version]`: semantic version (e.g. `1.2.3`); if omitted, auto-increment patch
- `[--channel=marketplace|github|both]`: publish target (default: both)

## Steps

1. **Pre-flight checks**:
   - `test -f .claude-plugin/plugin.json` or exit (not a plugin directory)
   - `git status --porcelain` (warn if uncommitted changes)
   - `test -f README.md CHANGELOG.md LICENSE` (required files)

2. **Validate structure**:
   - `.claude-plugin/plugin.json` is valid JSON
   - `.claude-plugin/marketplace.json` exists
   - At least one agent or command exists

3. **Determine version**:
   - If not provided, read current version from `plugin.json`
   - Suggest next patch version (e.g. 1.2.3 → 1.2.4)
   - Allow user override if needed

4. **Update version** in:
   - `.claude-plugin/plugin.json`: `"version": "<new-version>"`
   - `.claude-plugin/marketplace.json`: `"version": "<new-version>"`

5. **Validate JSON files**:
   ```bash
   jq . .claude-plugin/plugin.json > /dev/null
   jq . .claude-plugin/marketplace.json > /dev/null
   ```

6. **Create git commit**:
   ```bash
   git add .
   git commit -m "Release v<version>"
   git tag -a v<version> -m "Release v<version>"
   ```

7. **Publish to GitHub** (if channel includes github):
   ```bash
   git push origin main
   git push origin v<version>
   gh release create v<version> --notes "See CHANGELOG.md"
   ```

8. **Report success**:
   - Version: old → new
   - Files modified: plugin.json, marketplace.json
   - Commit & tag created
   - Release URLs (if published)
   - Next steps: verify release, test installation
