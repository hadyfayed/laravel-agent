---
name: git-commit
description: Stage and create a well-formed git commit for the current changes. Manual invoke only.
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *) Bash(git log *)
argument-hint: "[optional message or scope]"
---

## Current changes

- Status: !`git status --short`
- Staged/unstaged diff: !`git diff HEAD`

## Task

Create a conventional commit for the changes above.

1. **Group related changes.** If nothing is staged, stage the relevant files with `git add`.
2. **Analyse the diff** to determine the correct conventional-commit type:
   - `feat` — new functionality
   - `fix` — bug correction
   - `refactor` — code restructuring without behaviour change
   - `test` — adding or updating tests
   - `chore` — build, config, tooling, dependency updates
   - `docs` — documentation only
   - `perf` — performance improvement
   - `style` — formatting, whitespace, punctuation (no logic change)
3. **Write the commit message** in the form `type(scope): subject`, honouring `$ARGUMENTS` if provided.
   - Subject line ≤ 72 characters, imperative mood ("add", "fix", "update" — not "added", "fixed").
   - Add a bullet-point body if the change is non-obvious or spans multiple concerns.
   - Reference issue numbers (`Closes #N`) where applicable.
4. **Do NOT add Co-Authored-By, AI attribution, or any mentions of Claude/AI** to the commit message.
5. Run `git commit -m "..."` to create the commit.
6. Show the final `git status` and `git log --oneline -1` after committing.

## Commit message templates (reference)

**Single concern**
```
feat(scope): add <thing>
```

**Multi-file feature**
```
feat(scope): add <feature>

- Detail change A
- Detail change B

Closes #<ticket>
```

**Bug fix**
```
fix(scope): resolve <issue>

<Brief description of root cause and fix>

Fixes #<ticket>
```

**Refactor**
```
refactor(scope): extract <target>

No functional changes.
```

**Breaking change**
```
feat(scope)!: <description>

BREAKING CHANGE: <what changed and migration path>
```

## Security and quality checks (optional, pre-commit)

Before committing, verify that staged files do not contain:
- Hardcoded credentials, API keys, or secrets
- Debug helpers (`dd(`, `dump(`, `var_dump(`, `console.log(`)
- TODO comments that should be resolved before merge

If any of the above are found, report them and pause — do not commit until the user confirms or resolves.

## Additional references

- `references/git-workflow.md` — branch strategy (GitFlow, branch naming), smart commit message generation rules, `/git:pr` and `/git:release` workflows, and pre-commit/pre-push review-system hook integration.
