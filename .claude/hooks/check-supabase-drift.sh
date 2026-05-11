#!/usr/bin/env bash
# PreToolUse hook: warns about uncommitted Supabase schema drift before git commits.
# Receives tool input JSON on stdin. Exits 1 (blocks the commit) if drift is detected.
#
# Skip this check for a single commit by setting SKIP_SUPABASE_CHECK=1.

set -euo pipefail

# Allow callers to opt out of the slow diff check
if [ "${SKIP_SUPABASE_CHECK:-0}" = "1" ]; then
  exit 0
fi

input=$(cat)

# Extract the bash command from the JSON tool input using Python (avoids matching
# against the commit message body which could contain "git commit" as text).
command=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', data).get('command', ''))
except Exception:
    pass
" 2>/dev/null || true)

# Only trigger on actual git commit invocations, not messages about them
if ! echo "$command" | grep -qE '^git commit'; then
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

diff_output=$(timeout 60 supabase db diff --password "$SUPABASE_DB_PASSWORD" 2>&1 || true)

# Ignore output that is only comments/blank lines — those are not real schema changes
real_changes=$(echo "$diff_output" | grep -vE '^(--|[[:space:]]*$)' | grep -cE '(CREATE|ALTER|DROP)' || true)

if [ "${real_changes:-0}" -gt 0 ]; then
  echo ""
  echo "ERROR: Uncommitted Supabase schema changes detected. Commit the migration first."
  echo ""
  echo "$diff_output"
  echo ""
  echo "Run /supabase-sync to capture the changes as a migration file, then retry the commit."
  echo "Or set SKIP_SUPABASE_CHECK=1 to bypass this check for the current commit."
  exit 1
fi

exit 0
