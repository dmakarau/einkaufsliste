---
name: commit
description: Drafts a git commit message for staged changes following the project's commit style. Run after staging files with git add.
---

You are helping write a git commit message for the Einkaufsliste Flutter project.

## Steps

1. Run `git diff --cached` to see exactly what is staged
2. Run `git log --oneline -5` to get a feel for the commit style in this repo
3. Draft a commit message following the rules below

## Commit message rules

- Plain English, no emojis, no references to AI or tools
- Imperative mood on the subject line: "Add", "Fix", "Update", "Remove"
- Subject line under 72 characters, specific enough to understand without reading the diff
- Optional body: explain the *why* (reasoning, context, tradeoff) — not just what changed
- Separate subject from body with a blank line

## Then commit

Run `git commit -m "..."` with the drafted message. Do not add any Co-Authored-By lines or tool signatures.

## Examples of good commit messages

```
Add category sync to Supabase on create and delete
```

```
Fix duplicate list appearing after sign-in

pullAll() was pushing re-seeded offline data before fetching remote,
creating a duplicate alongside the original. Removed push-local-first
so Supabase is always the source of truth on sign-in.
```

```
Update .gitignore to exclude .dart_defines
```
