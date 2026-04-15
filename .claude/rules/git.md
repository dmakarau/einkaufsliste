# Git Rules

## Commit Messages

- Write in plain English, as a human developer would
- No emojis anywhere in commit messages
- No references to AI tools, assistants, or code generators
- Use imperative mood for the subject line: "Add feature", "Fix bug", "Update config"
- Subject line: short and specific (under 72 characters)
- Body (optional): explain *why*, not *what* — the diff shows the what

**Good:**
```
Fix sign-out not clearing shopping list UI

Hive was cleared after emitting AuthUnauthenticated, causing loadLists()
to run against stale data. Moved clearAll() calls to before the emit.
```

**Bad:**
```
✨ Fix bug with sign-out (Claude helped fix this race condition)
```

## Commit Scope

- One logical change per commit
- Do not batch unrelated changes together
- Staged files should reflect exactly what the commit message describes

## Branch Naming

- Feature branches: `feature/short-description`
- Bug fixes: `fix/short-description`
- Refactors: `refactor/short-description`

## Before Every Commit

Always run `dart format lib/ test/` before staging files. CI enforces `dart format --set-exit-if-changed` and will fail if formatting is off. The formatter adjusts trailing commas, line lengths, and indentation — changes that aren't always visible without running it.

```bash
dart format lib/ test/
git add <files>
# then commit
```

## What Not to Commit

- `.dart_defines` — gitignored, contains real Supabase credentials
- `*.local.dart` — gitignored
- Generated files that are already gitignored (`build/`, `.dart_tool/`)
- Debug print statements left in production code
