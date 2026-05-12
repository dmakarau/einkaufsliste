-- Replace the shopping_items RLS policies with a list-based access model.
--
-- Problem: the previous policies had an `owner_id = auth.uid()` OR shortcut
-- that let a removed member SELECT their own items (and UPDATE/DELETE them)
-- even in lists they no longer have access to.  After pullAll() this produced
-- orphaned items in Hive with no parent list visible in the UI.
--
-- Fix: access to items is now fully derived from access to the parent list.
-- A user can see / modify an item if and only if they can see the list it
-- belongs to (they own the list, or the list is shared with a group they are
-- an accepted member of).

drop policy if exists "users manage own items" on "public"."shopping_items";
drop policy if exists "select_items"           on "public"."shopping_items";
drop policy if exists "insert_items"           on "public"."shopping_items";
drop policy if exists "update_items"           on "public"."shopping_items";
drop policy if exists "delete_items"           on "public"."shopping_items";

-- SELECT: visible iff the parent list is visible to you
create policy "select_items"
  on "public"."shopping_items"
  as permissive for select to public
  using (
    list_id in (
      select id from public.shopping_lists
      where owner_id = auth.uid()
         or family_group_id in (select public.get_my_accepted_group_ids())
    )
  );

-- INSERT: you can only write as yourself, into a list you can access
create policy "insert_items"
  on "public"."shopping_items"
  as permissive for insert to public
  with check (
    owner_id = auth.uid()
    and list_id in (
      select id from public.shopping_lists
      where owner_id = auth.uid()
         or family_group_id in (select public.get_my_accepted_group_ids())
    )
  );

-- UPDATE: list-access gate only (no owner_id shortcut)
create policy "update_items"
  on "public"."shopping_items"
  as permissive for update to public
  using (
    list_id in (
      select id from public.shopping_lists
      where owner_id = auth.uid()
         or family_group_id in (select public.get_my_accepted_group_ids())
    )
  );

-- DELETE: list-access gate only
create policy "delete_items"
  on "public"."shopping_items"
  as permissive for delete to public
  using (
    list_id in (
      select id from public.shopping_lists
      where owner_id = auth.uid()
         or family_group_id in (select public.get_my_accepted_group_ids())
    )
  );
