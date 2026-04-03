---
description: "Publish a Claude Code plugin to marketplace or create a GitHub release"
allowed-tools: Task, Read, Glob, Grep, Bash, Write, Edit, MultiEdit
---

# /plugin:publish - Publish Claude Code Plugin

Prepare and publish a Claude Code plugin to the marketplace or GitHub.

## Input
$ARGUMENTS = `[version] [--channel=marketplace|github|both]`

Examples:
- `/plugin:publish` (auto-increment patch version)
- `/plugin:publish 2.0.0` (specific version)
- `/plugin:publish --channel=github` (GitHub release only)
- `/plugin:publish 1.5.0 --channel=both` (marketplace + GitHub)

## Process

1. **Pre-flight Checks**

   ```bash
   # Verify we're in a plugin directory
   ls .claude-plugin/plugin.json || echo "Not a plugin directory"

   # Check git status
   git status --porcelain

   # Verify required files exist
   ls README.md CHANGELOG.md LICENSE .claude-plugin/marketplace.json
   ```

2. **Validate Plugin Structure**

   Required files:
   - [ ] `.claude-plugin/plugin.json` - Valid JSON with name, version
   - [ ] `.claude-plugin/marketplace.json` - Valid marketplace listing
   - [ ] `README.md` - Installation instructions
   - [ ] `CHANGELOG.md` - Version history
   - [ ] `LICENSE` - License file
   - [ ] At least one agent or command

   ```
   ⚠️  Missing required files will block publishing
   ```

3. **Determine Version**

   If not provided:
   - Read current version from plugin.json
   - Suggest next version based on changes:
     - **Major** (x.0.0): Breaking changes
     - **Minor** (0.x.0): New features
     - **Patch** (0.0.x): Bug fixes

   Ask user:
   ```
   Current version: 1.2.3
   Suggested version: 1.2.4 (patch)

   Select version type:
   - Patch (1.2.4) - Bug fixes only
   - Minor (1.3.0) - New features
   - Major (2.0.0) - Breaking changes
   - Custom: Enter specific version
   ```

4. **Update Version Numbers**

   Update in all locations:

   **plugin.json:**
   ```json
   {
     "version": "<new-version>"
   }
   ```

   **marketplace.json:**
   ```json
   {
     "plugins": [{
       "version": "<new-version>"
     }]
   }
   ```

5. **Generate/Update CHANGELOG**

   If not already updated, generate entry:

   ```markdown
   ## [<version>] - <date>

   ### Added
   - <new features>

   ### Changed
   - <modifications>

   ### Fixed
   - <bug fixes>

   ### Removed
   - <removed features>
   ```

   Ask user to confirm or edit.

6. **Run Validation**

   ```bash
   # Validate JSON files
   jq . .claude-plugin/plugin.json > /dev/null
   jq . .claude-plugin/marketplace.json > /dev/null

   # Check for common issues
   grep -r "TODO" agents/ commands/ || echo "No TODOs found"
   grep -r "FIXME" agents/ commands/ || echo "No FIXMEs found"
   ```

7. **Create Git Commit & Tag**

   ```bash
   git add .
   git commit -m "Release v<version>

   <changelog-entry>

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

   git tag -a v<version> -m "Release v<version>"
   ```

8. **Publish to GitHub** (if channel includes github)

   ```bash
   # Push changes
   git push origin main
   git push origin v<version>

   # Create GitHub release
   gh release create v<version> \
     --title "v<version>" \
     --notes "<changelog-entry>" \
     --latest
   ```

9. **Publish to Marketplace** (if channel includes marketplace)

   ```
   Marketplace publishing steps:
   1. Ensure GitHub repo is public
   2. Verify marketplace.json is correct
   3. Submit via: /plugin marketplace add <owner>/<repo>

   Note: Marketplace publishing may require manual approval.
   ```

10. **Report Success**

    ```markdown
    ## Plugin Published: v<version>

    ### Version Updated
    - Previous: <old-version>
    - Current: <new-version>

    ### Files Modified
    - `.claude-plugin/plugin.json`
    - `.claude-plugin/marketplace.json`
    - `CHANGELOG.md`

    ### Git
    - Commit: <commit-hash>
    - Tag: v<version>

    ### Distribution
    - GitHub Release: <url>
    - Marketplace: <status>

    ### Installation Command
    ```bash
    /plugin marketplace add <owner>/<plugin-name>
    /plugin install <plugin-name>@<owner>-<plugin-name>
    ```

    ### Next Steps
    1. Verify GitHub release: <url>
    2. Test installation in a fresh environment
    3. Announce the release
    ```

## Version Guidelines

### When to Use Each Version Type

| Change Type | Version | Example |
|-------------|---------|---------|
| Bug fixes, typos | Patch (0.0.x) | 1.2.3 → 1.2.4 |
| New command/agent | Minor (0.x.0) | 1.2.3 → 1.3.0 |
| New major feature | Minor (0.x.0) | 1.2.3 → 1.3.0 |
| Breaking changes | Major (x.0.0) | 1.2.3 → 2.0.0 |
| Renamed commands | Major (x.0.0) | 1.2.3 → 2.0.0 |
| Removed features | Major (x.0.0) | 1.2.3 → 2.0.0 |

### Breaking Changes Include

- Renamed agents or commands
- Changed command arguments
- Removed features
- Changed tool permissions
- Modified output formats

## Rollback

If something goes wrong:

```bash
# Undo last commit (before push)
git reset --soft HEAD~1

# Delete local tag
git tag -d v<version>

# If already pushed:
git push origin --delete v<version>
gh release delete v<version> --yes
```
