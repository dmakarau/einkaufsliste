Capture any uncommitted Supabase schema changes as a new migration file and commit it.

## Steps

1. Resolve the DB password:
   - Check the `SUPABASE_DB_PASSWORD` environment variable first
   - Fall back to `.env.supabase` file: `grep SUPABASE_DB_PASSWORD .env.supabase | cut -d= -f2`
   - If neither exists, tell the user to add it to `.env.supabase`

2. Ask the user for a short name describing the change (e.g. `add_archived_column`, `update_rls_policy`). Use it as the `-f` flag.

3. Run the diff:
   ```
   supabase db diff --password <password> -f <name>
   ```

4. Check `supabase/migrations/` for a newly created file. If it is empty or missing, report that the schema is already in sync and stop.

5. If a non-empty migration file was created:
   - Stage it: `git add supabase/migrations/`
   - Use the commit agent to commit with a message describing the schema change

## Notes
- `supabase db diff` requires Docker Desktop to be running
- The generated file goes into `supabase/migrations/<timestamp>_<name>.sql`
- Never commit `.env.supabase` — it is gitignored
