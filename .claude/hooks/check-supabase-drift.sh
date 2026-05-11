#!/usr/bin/env bash
# PreToolUse hook: warns about uncommitted Supabase schema drift before git commits.
# Receives tool input JSON on stdin. Exits 1 (blocks the commit) if drift is detected.

set -euo pipefail

input=$(cat)

# Only trigger on git commit commands
if ! echo "$input" | grep -q '"git commit'; then
  exit 0
fi

# Skip if no supabase project is configured
if [ ! -f supabase/config.toml ]; then
  exit 0
fi

# Resolve DB password: env var → .env.supabase file
if [ -z "${SUPABASE_DB_PASSWORD:-}" ] && [ -f .env.supabase ]; then
  SUPABASE_DB_PASSWORD=$(grep -m1 '^SUPABASE_DB_PASSWORD=' .env.supabase | cut -d= -f2-)
fi

if [ -z "${SUPABASE_DB_PASSWORD:-}" ]; then
  echo "Supabase drift check skipped: set SUPABASE_DB_PASSWORD in .env.supabase to enable."
  exit 0
fi

echo "Checking for uncommitted Supabase schema changes..."

diff_output=$(supabase db diff --password "$SUPABASE_DB_PASSWORD" 2>&1 || true)

# Ignore output that is only comments/blank lines — those are not real schema changes
real_changes=$(echo "$diff_output" | grep -vE '^(--|[[:space:]]*$)' | grep -cE '(CREATE|ALTER|DROP)' || true)

if [ "${real_changes:-0}" -gt 0 ]; then
  echo ""
  echo "ERROR: Uncommitted Supabase schema changes detected. Commit the migration first."
  echo ""
  echo "$diff_output"
  echo ""
  echo "Run /supabase-sync to capture the changes as a migration file, then retry the commit."
  exit 1
fi

exit 0
