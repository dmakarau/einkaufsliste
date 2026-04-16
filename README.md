# Einkaufsliste

[![CI](https://github.com/dmakarau/einkaufsliste/actions/workflows/ci.yml/badge.svg)](https://github.com/dmakarau/einkaufsliste/actions/workflows/ci.yml)

A German shopping list app for iOS and Android built with Flutter. Supports multiple lists, colour-coded categories, offline-first storage, and per-account cloud sync via Supabase.

## Features

- Multiple named shopping lists (one protected default list)
- Items with name, quantity, unit, category, and optional photo
- 13 default categories with colour coding
- Check/uncheck items; delete or edit at any time
- Sign up / sign in / sign out — data synced to your Supabase account
- Offline-first: works without internet, syncs on sign-in and automatically when the app returns to the foreground
- Family group sharing — create a group, invite members by email, share individual lists; changes sync in real-time between members
- German / English / Russian UI (follows device locale, manual override in Settings)

## Technologies & Frameworks

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-FF7A00?style=for-the-badge&logo=hive&logoColor=white)
![BLoC](https://img.shields.io/badge/flutter__bloc-4A148C?style=for-the-badge&logoColor=white)
![go_router](https://img.shields.io/badge/go__router-02569B?style=for-the-badge&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

## Getting Started

### 1. Clone and install dependencies

```bash
git clone https://github.com/dmakarau/einkaufsliste.git
cd einkaufsliste
flutter pub get
```

### 2. Set up Supabase credentials

Copy the example secrets file and fill in your own values:

```bash
cp .dart_defines.example .dart_defines
```

Edit `.dart_defines` (never commit this file — it is gitignored):

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_ID.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_ANON_KEY_HERE"
}
```

Find these values in your Supabase dashboard → Project Settings → API.

### 3. Set up the Supabase database

Run the SQL below in the Supabase SQL Editor (one time, in order).

Also disable **Confirm email** in Supabase → Authentication → Providers → Email (required for immediate sign-in).

#### Step 1 — Core tables

```sql
-- Shopping lists (one per user or shared with a family group)
create table if not exists shopping_lists (
  id              uuid primary key,
  owner_id        uuid references auth.users not null,
  family_group_id uuid,                         -- set when shared with a group
  name            text not null,
  is_default      boolean not null default false,
  created_at      timestamptz not null,
  updated_at      timestamptz not null default now()
);

-- Shopping items
create table if not exists shopping_items (
  id          uuid primary key,
  list_id     uuid references shopping_lists(id) on delete cascade not null,
  owner_id    uuid references auth.users not null,
  name        text not null,
  quantity    double precision not null default 1,
  unit        text not null default 'Stk.',
  category_id uuid not null,
  is_checked  boolean not null default false,
  image_path  text,
  created_at  timestamptz not null,
  updated_at  timestamptz not null default now()
);

-- Categories (per user; family_group_id reserved for future category sharing)
create table if not exists categories (
  id              uuid primary key,
  owner_id        uuid references auth.users not null,
  family_group_id uuid,
  name            text not null,
  color_value     bigint not null,
  sort_order      int not null default 0,
  is_default      boolean not null default false,
  created_at      timestamptz not null,
  updated_at      timestamptz not null default now()
);

alter table shopping_lists enable row level security;
alter table shopping_items  enable row level security;
alter table categories      enable row level security;
```

#### Step 2 — Family group tables

```sql
-- Family groups (one group per user; owner_id = creator)
create table if not exists family_groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  owner_id   uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table family_groups enable row level security;

-- Members + pending invitations (invite by email, accepted on sign-in)
create table if not exists family_group_members (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references family_groups(id) on delete cascade,
  user_id    uuid references auth.users(id) on delete set null,
  email      text not null,
  role       text not null default 'member',   -- 'admin' | 'member'
  status     text not null default 'pending',  -- 'pending' | 'accepted'
  invited_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(group_id, email)
);
alter table family_group_members enable row level security;

-- FK from shopping_lists / categories to family_groups
alter table shopping_lists
  add constraint shopping_lists_family_group_id_fkey
  foreign key (family_group_id) references family_groups(id) on delete set null;

alter table categories
  add constraint categories_family_group_id_fkey
  foreign key (family_group_id) references family_groups(id) on delete set null;
```

#### Step 3 — RLS policies

```sql
-- family_groups
-- Note: the third clause lets invited users see the group name before they accept.
-- Without it, pending invitees see '—' as the group name until acceptance.
create policy "select_my_group" on family_groups for select using (
  owner_id = auth.uid()
  or id in (
    select group_id from family_group_members
    where user_id = auth.uid() and status = 'accepted'
  )
  or id in (
    select group_id from family_group_members
    where email = (select email from auth.users where id = auth.uid())
      and status = 'pending'
  )
);
create policy "insert_group" on family_groups for insert
  with check (owner_id = auth.uid());
create policy "delete_group" on family_groups for delete
  using (owner_id = auth.uid());

-- family_group_members
create policy "select_members" on family_group_members for select using (
  user_id = auth.uid()
  or email = (select email from auth.users where id = auth.uid())
  or group_id in (
    select group_id from family_group_members
    where user_id = auth.uid() and status = 'accepted'
  )
);
create policy "insert_invite" on family_group_members for insert
  with check (
    group_id in (select id from family_groups where owner_id = auth.uid())
  );
create policy "update_member" on family_group_members for update using (
  user_id = auth.uid()
  or email = (select email from auth.users where id = auth.uid())
  or group_id in (select id from family_groups where owner_id = auth.uid())
);
create policy "delete_member" on family_group_members for delete using (
  user_id = auth.uid()
  or group_id in (select id from family_groups where owner_id = auth.uid())
);

-- shopping_lists: own lists + lists shared via family group
create policy "select_lists" on shopping_lists for select using (
  owner_id = auth.uid()
  or family_group_id in (
    select group_id from family_group_members
    where user_id = auth.uid() and status = 'accepted'
  )
);
create policy "insert_lists" on shopping_lists for insert
  with check (owner_id = auth.uid());
create policy "update_lists" on shopping_lists for update
  using (owner_id = auth.uid());
create policy "delete_lists" on shopping_lists for delete
  using (owner_id = auth.uid());

-- shopping_items: own items + items in group-shared lists
create policy "select_items" on shopping_items for select using (
  owner_id = auth.uid()
  or list_id in (
    select id from shopping_lists
    where family_group_id in (
      select group_id from family_group_members
      where user_id = auth.uid() and status = 'accepted'
    )
  )
);
create policy "insert_items" on shopping_items for insert
  with check (
    owner_id = auth.uid()
    or list_id in (
      select id from shopping_lists
      where family_group_id in (
        select group_id from family_group_members
        where user_id = auth.uid() and status = 'accepted'
      )
    )
  );
create policy "update_items" on shopping_items for update using (
  owner_id = auth.uid()
  or list_id in (
    select id from shopping_lists
    where family_group_id in (
      select group_id from family_group_members
      where user_id = auth.uid() and status = 'accepted'
    )
  )
);
create policy "delete_items" on shopping_items for delete using (
  owner_id = auth.uid()
  or list_id in (
    select id from shopping_lists
    where family_group_id in (
      select group_id from family_group_members
      where user_id = auth.uid() and status = 'accepted'
    )
  )
);

-- categories: own only
create policy "manage_categories" on categories
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

#### Step 4 — Enable Realtime

In Supabase Dashboard → Database → Replication, add these tables to the realtime publication:
- `shopping_lists`
- `shopping_items`
- `family_group_members`

### 4. Set up Supabase Storage

In the Supabase dashboard → Storage, create a bucket named **`shopping-item-images`** and set it to **Public**. Then add an RLS policy so users can only manage their own files:

```sql
create policy "users manage own images"
on storage.objects for all
to authenticated
using (bucket_id = 'shopping-item-images' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'shopping-item-images' and (storage.foldername(name))[1] = auth.uid()::text);
```

Images are uploaded automatically when an item with a local photo is synced.

### 5. Configure GitHub Actions secrets

For CI builds to use real Supabase credentials, add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret | Value |
|--------|-------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |

CI runs without these secrets will use placeholder values (build compiles, but app cannot connect to Supabase at runtime).

### 6. Run the app

```bash
flutter run --dart-define-from-file=.dart_defines
```

Or use the pre-configured VS Code launch config **"Einkaufsliste (debug)"** — it passes `--dart-define-from-file` automatically.

## CI / CD

GitHub Actions workflows live in `.github/workflows/`:

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | Push / PR to `main` | Lint, format, tests, Android debug APK, web build (all Ubuntu) |
| `release.yml` | `v*` tag push | Android release AAB (Ubuntu) + iOS no-codesign build (macOS) |

## Project Structure

```
lib/
├── core/           # Theme, router, constants, extensions
├── data/
│   ├── models/     # Hive-annotated data models
│   ├── repositories/  # CRUD over Hive boxes
│   └── services/   # SupabaseSyncService (cloud I/O)
└── presentation/
    ├── blocs/      # Cubits + States
    ├── screens/    # One folder per screen
    └── widgets/    # Shared widgets
```

See `.claude/rules/` for architecture and Flutter coding conventions used in this project.

## Key Commands

```bash
flutter run --dart-define-from-file=.dart_defines        # run with Supabase
flutter test                                              # run tests
flutter analyze                                           # lint
dart format lib/                                          # format
flutter gen-l10n                                          # regen translations (after editing .arb files)
dart run build_runner build --delete-conflicting-outputs  # regen Hive adapters (after model changes)
```
