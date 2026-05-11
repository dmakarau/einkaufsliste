drop extension if exists "pg_net";


  create table "public"."categories" (
    "id" uuid not null,
    "owner_id" uuid not null,
    "family_group_id" uuid,
    "name" text not null,
    "color_value" bigint not null,
    "sort_order" integer not null default 0,
    "is_default" boolean not null default false,
    "created_at" timestamp with time zone not null,
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."categories" enable row level security;


  create table "public"."family_group_members" (
    "id" uuid not null default gen_random_uuid(),
    "group_id" uuid not null,
    "user_id" uuid,
    "email" text not null,
    "role" text not null default 'member'::text,
    "status" text not null default 'pending'::text,
    "invited_by" uuid,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."family_group_members" enable row level security;


  create table "public"."family_groups" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "owner_id" uuid not null,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."family_groups" enable row level security;


  create table "public"."shopping_items" (
    "id" uuid not null,
    "list_id" uuid not null,
    "owner_id" uuid not null,
    "name" text not null,
    "quantity" double precision not null default 1,
    "unit" text not null default 'Stk.'::text,
    "category_id" uuid not null,
    "is_checked" boolean not null default false,
    "image_path" text,
    "created_at" timestamp with time zone not null,
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."shopping_items" enable row level security;


  create table "public"."shopping_lists" (
    "id" uuid not null,
    "owner_id" uuid not null,
    "family_group_id" uuid,
    "name" text not null,
    "is_default" boolean not null default false,
    "created_at" timestamp with time zone not null,
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."shopping_lists" enable row level security;

CREATE UNIQUE INDEX categories_pkey ON public.categories USING btree (id);

CREATE UNIQUE INDEX family_group_members_group_id_email_key ON public.family_group_members USING btree (group_id, email);

CREATE UNIQUE INDEX family_group_members_pkey ON public.family_group_members USING btree (id);

CREATE UNIQUE INDEX family_groups_pkey ON public.family_groups USING btree (id);

CREATE UNIQUE INDEX shopping_items_pkey ON public.shopping_items USING btree (id);

CREATE UNIQUE INDEX shopping_lists_pkey ON public.shopping_lists USING btree (id);

alter table "public"."categories" add constraint "categories_pkey" PRIMARY KEY using index "categories_pkey";

alter table "public"."family_group_members" add constraint "family_group_members_pkey" PRIMARY KEY using index "family_group_members_pkey";

alter table "public"."family_groups" add constraint "family_groups_pkey" PRIMARY KEY using index "family_groups_pkey";

alter table "public"."shopping_items" add constraint "shopping_items_pkey" PRIMARY KEY using index "shopping_items_pkey";

alter table "public"."shopping_lists" add constraint "shopping_lists_pkey" PRIMARY KEY using index "shopping_lists_pkey";

alter table "public"."categories" add constraint "categories_family_group_id_fkey" FOREIGN KEY (family_group_id) REFERENCES public.family_groups(id) ON DELETE SET NULL not valid;

alter table "public"."categories" validate constraint "categories_family_group_id_fkey";

alter table "public"."categories" add constraint "categories_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES auth.users(id) not valid;

alter table "public"."categories" validate constraint "categories_owner_id_fkey";

alter table "public"."family_group_members" add constraint "family_group_members_group_id_email_key" UNIQUE using index "family_group_members_group_id_email_key";

alter table "public"."family_group_members" add constraint "family_group_members_group_id_fkey" FOREIGN KEY (group_id) REFERENCES public.family_groups(id) ON DELETE CASCADE not valid;

alter table "public"."family_group_members" validate constraint "family_group_members_group_id_fkey";

alter table "public"."family_group_members" add constraint "family_group_members_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES auth.users(id) not valid;

alter table "public"."family_group_members" validate constraint "family_group_members_invited_by_fkey";

alter table "public"."family_group_members" add constraint "family_group_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."family_group_members" validate constraint "family_group_members_user_id_fkey";

alter table "public"."family_groups" add constraint "family_groups_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."family_groups" validate constraint "family_groups_owner_id_fkey";

alter table "public"."shopping_items" add constraint "shopping_items_list_id_fkey" FOREIGN KEY (list_id) REFERENCES public.shopping_lists(id) ON DELETE CASCADE not valid;

alter table "public"."shopping_items" validate constraint "shopping_items_list_id_fkey";

alter table "public"."shopping_items" add constraint "shopping_items_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES auth.users(id) not valid;

alter table "public"."shopping_items" validate constraint "shopping_items_owner_id_fkey";

alter table "public"."shopping_lists" add constraint "shopping_lists_family_group_id_fkey" FOREIGN KEY (family_group_id) REFERENCES public.family_groups(id) ON DELETE SET NULL not valid;

alter table "public"."shopping_lists" validate constraint "shopping_lists_family_group_id_fkey";

alter table "public"."shopping_lists" add constraint "shopping_lists_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES auth.users(id) not valid;

alter table "public"."shopping_lists" validate constraint "shopping_lists_owner_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_my_accepted_group_ids()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select group_id
  from family_group_members
  where user_id = auth.uid() and status = 'accepted'
$function$
;

CREATE OR REPLACE FUNCTION public.touch_list_on_item_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$                                                                                                                                                                                
  BEGIN                                           
    UPDATE shopping_lists                                                                                                                                                                              
    SET updated_at = NOW()                            
    WHERE id = COALESCE(NEW.list_id, OLD.list_id);
    RETURN COALESCE(NEW, OLD);                                                                                                                                                                         
  END;
  $function$
;

grant delete on table "public"."categories" to "anon";

grant insert on table "public"."categories" to "anon";

grant references on table "public"."categories" to "anon";

grant select on table "public"."categories" to "anon";

grant trigger on table "public"."categories" to "anon";

grant truncate on table "public"."categories" to "anon";

grant update on table "public"."categories" to "anon";

grant delete on table "public"."categories" to "authenticated";

grant insert on table "public"."categories" to "authenticated";

grant references on table "public"."categories" to "authenticated";

grant select on table "public"."categories" to "authenticated";

grant trigger on table "public"."categories" to "authenticated";

grant truncate on table "public"."categories" to "authenticated";

grant update on table "public"."categories" to "authenticated";

grant delete on table "public"."categories" to "service_role";

grant insert on table "public"."categories" to "service_role";

grant references on table "public"."categories" to "service_role";

grant select on table "public"."categories" to "service_role";

grant trigger on table "public"."categories" to "service_role";

grant truncate on table "public"."categories" to "service_role";

grant update on table "public"."categories" to "service_role";

grant delete on table "public"."family_group_members" to "anon";

grant insert on table "public"."family_group_members" to "anon";

grant references on table "public"."family_group_members" to "anon";

grant select on table "public"."family_group_members" to "anon";

grant trigger on table "public"."family_group_members" to "anon";

grant truncate on table "public"."family_group_members" to "anon";

grant update on table "public"."family_group_members" to "anon";

grant delete on table "public"."family_group_members" to "authenticated";

grant insert on table "public"."family_group_members" to "authenticated";

grant references on table "public"."family_group_members" to "authenticated";

grant select on table "public"."family_group_members" to "authenticated";

grant trigger on table "public"."family_group_members" to "authenticated";

grant truncate on table "public"."family_group_members" to "authenticated";

grant update on table "public"."family_group_members" to "authenticated";

grant delete on table "public"."family_group_members" to "service_role";

grant insert on table "public"."family_group_members" to "service_role";

grant references on table "public"."family_group_members" to "service_role";

grant select on table "public"."family_group_members" to "service_role";

grant trigger on table "public"."family_group_members" to "service_role";

grant truncate on table "public"."family_group_members" to "service_role";

grant update on table "public"."family_group_members" to "service_role";

grant delete on table "public"."family_groups" to "anon";

grant insert on table "public"."family_groups" to "anon";

grant references on table "public"."family_groups" to "anon";

grant select on table "public"."family_groups" to "anon";

grant trigger on table "public"."family_groups" to "anon";

grant truncate on table "public"."family_groups" to "anon";

grant update on table "public"."family_groups" to "anon";

grant delete on table "public"."family_groups" to "authenticated";

grant insert on table "public"."family_groups" to "authenticated";

grant references on table "public"."family_groups" to "authenticated";

grant select on table "public"."family_groups" to "authenticated";

grant trigger on table "public"."family_groups" to "authenticated";

grant truncate on table "public"."family_groups" to "authenticated";

grant update on table "public"."family_groups" to "authenticated";

grant delete on table "public"."family_groups" to "service_role";

grant insert on table "public"."family_groups" to "service_role";

grant references on table "public"."family_groups" to "service_role";

grant select on table "public"."family_groups" to "service_role";

grant trigger on table "public"."family_groups" to "service_role";

grant truncate on table "public"."family_groups" to "service_role";

grant update on table "public"."family_groups" to "service_role";

grant delete on table "public"."shopping_items" to "anon";

grant insert on table "public"."shopping_items" to "anon";

grant references on table "public"."shopping_items" to "anon";

grant select on table "public"."shopping_items" to "anon";

grant trigger on table "public"."shopping_items" to "anon";

grant truncate on table "public"."shopping_items" to "anon";

grant update on table "public"."shopping_items" to "anon";

grant delete on table "public"."shopping_items" to "authenticated";

grant insert on table "public"."shopping_items" to "authenticated";

grant references on table "public"."shopping_items" to "authenticated";

grant select on table "public"."shopping_items" to "authenticated";

grant trigger on table "public"."shopping_items" to "authenticated";

grant truncate on table "public"."shopping_items" to "authenticated";

grant update on table "public"."shopping_items" to "authenticated";

grant delete on table "public"."shopping_items" to "service_role";

grant insert on table "public"."shopping_items" to "service_role";

grant references on table "public"."shopping_items" to "service_role";

grant select on table "public"."shopping_items" to "service_role";

grant trigger on table "public"."shopping_items" to "service_role";

grant truncate on table "public"."shopping_items" to "service_role";

grant update on table "public"."shopping_items" to "service_role";

grant delete on table "public"."shopping_lists" to "anon";

grant insert on table "public"."shopping_lists" to "anon";

grant references on table "public"."shopping_lists" to "anon";

grant select on table "public"."shopping_lists" to "anon";

grant trigger on table "public"."shopping_lists" to "anon";

grant truncate on table "public"."shopping_lists" to "anon";

grant update on table "public"."shopping_lists" to "anon";

grant delete on table "public"."shopping_lists" to "authenticated";

grant insert on table "public"."shopping_lists" to "authenticated";

grant references on table "public"."shopping_lists" to "authenticated";

grant select on table "public"."shopping_lists" to "authenticated";

grant trigger on table "public"."shopping_lists" to "authenticated";

grant truncate on table "public"."shopping_lists" to "authenticated";

grant update on table "public"."shopping_lists" to "authenticated";

grant delete on table "public"."shopping_lists" to "service_role";

grant insert on table "public"."shopping_lists" to "service_role";

grant references on table "public"."shopping_lists" to "service_role";

grant select on table "public"."shopping_lists" to "service_role";

grant trigger on table "public"."shopping_lists" to "service_role";

grant truncate on table "public"."shopping_lists" to "service_role";

grant update on table "public"."shopping_lists" to "service_role";


  create policy "users manage own categories"
  on "public"."categories"
  as permissive
  for all
  to public
using ((owner_id = auth.uid()))
with check ((owner_id = auth.uid()));



  create policy "delete_member"
  on "public"."family_group_members"
  as permissive
  for delete
  to public
using (((user_id = auth.uid()) OR (group_id IN ( SELECT family_groups.id
   FROM public.family_groups
  WHERE (family_groups.owner_id = auth.uid())))));



  create policy "insert_invite"
  on "public"."family_group_members"
  as permissive
  for insert
  to public
with check ((group_id IN ( SELECT family_groups.id
   FROM public.family_groups
  WHERE (family_groups.owner_id = auth.uid()))));



  create policy "select_members"
  on "public"."family_group_members"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR (email = auth.email()) OR (group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids)) OR (group_id IN ( SELECT family_groups.id
   FROM public.family_groups
  WHERE (family_groups.owner_id = auth.uid())))));



  create policy "update_member"
  on "public"."family_group_members"
  as permissive
  for update
  to public
using (((user_id = auth.uid()) OR (email = auth.email()) OR (group_id IN ( SELECT family_groups.id
   FROM public.family_groups
  WHERE (family_groups.owner_id = auth.uid())))));



  create policy "delete_group"
  on "public"."family_groups"
  as permissive
  for delete
  to public
using ((owner_id = auth.uid()));



  create policy "insert_group"
  on "public"."family_groups"
  as permissive
  for insert
  to public
with check ((owner_id = auth.uid()));



  create policy "select_my_group"
  on "public"."family_groups"
  as permissive
  for select
  to public
using (((owner_id = auth.uid()) OR (id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))));



  create policy "delete_items"
  on "public"."shopping_items"
  as permissive
  for delete
  to public
using (((owner_id = auth.uid()) OR (list_id IN ( SELECT shopping_lists.id
   FROM public.shopping_lists
  WHERE (shopping_lists.family_group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))))));



  create policy "insert_items"
  on "public"."shopping_items"
  as permissive
  for insert
  to public
with check (((owner_id = auth.uid()) OR (list_id IN ( SELECT shopping_lists.id
   FROM public.shopping_lists
  WHERE (shopping_lists.family_group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))))));



  create policy "select_items"
  on "public"."shopping_items"
  as permissive
  for select
  to public
using (((owner_id = auth.uid()) OR (list_id IN ( SELECT shopping_lists.id
   FROM public.shopping_lists
  WHERE (shopping_lists.family_group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))))));



  create policy "update_items"
  on "public"."shopping_items"
  as permissive
  for update
  to public
using (((owner_id = auth.uid()) OR (list_id IN ( SELECT shopping_lists.id
   FROM public.shopping_lists
  WHERE (shopping_lists.family_group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))))));



  create policy "users manage own items"
  on "public"."shopping_items"
  as permissive
  for all
  to public
using ((owner_id = auth.uid()))
with check ((owner_id = auth.uid()));



  create policy "select_lists"
  on "public"."shopping_lists"
  as permissive
  for select
  to public
using (((owner_id = auth.uid()) OR (family_group_id IN ( SELECT public.get_my_accepted_group_ids() AS get_my_accepted_group_ids))));



  create policy "users manage own lists"
  on "public"."shopping_lists"
  as permissive
  for all
  to public
using ((owner_id = auth.uid()))
with check ((owner_id = auth.uid()));


CREATE TRIGGER shopping_items_touch_list AFTER INSERT OR DELETE OR UPDATE ON public.shopping_items FOR EACH ROW EXECUTE FUNCTION public.touch_list_on_item_change();


  create policy "Public image read 12xn43x_0"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'shopping-item-images'::text));



  create policy "Users upload own images 12xn43x_0"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'shopping-item-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)));



