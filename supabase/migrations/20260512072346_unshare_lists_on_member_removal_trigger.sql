-- When an accepted member is removed from a family group, automatically
-- unshare all shopping lists they owned that were shared with that group.
-- This prevents stale shared-list visibility after removal and avoids the
-- need for any client-side cleanup. Pending invites (user_id IS NULL) are
-- skipped because they have no associated lists to unshare.

-- SECURITY DEFINER is required: the trigger fires in the session of whoever
-- called DELETE (the admin), and RLS on shopping_lists only allows the list
-- owner to UPDATE. Without SECURITY DEFINER the UPDATE is silently blocked.
create or replace function public.unshare_lists_on_member_removal()
  returns trigger language plpgsql security definer as $$
begin
  if old.user_id is not null then
    update public.shopping_lists
    set family_group_id = null
    where owner_id = old.user_id
      and family_group_id = old.group_id;
  end if;
  return old;
end;
$$;

create trigger unshare_lists_on_member_removal
  after delete on public.family_group_members
  for each row execute procedure public.unshare_lists_on_member_removal();
