# Einkaufsliste

A German shopping list app for iOS and Android built with Flutter. Supports multiple lists, colour-coded categories, offline-first storage, and per-account cloud sync via Supabase.

## Features

- Multiple named shopping lists (one protected default list)
- Items with name, quantity, unit, category, and optional photo
- 13 default categories with colour coding
- Check/uncheck items; delete or edit at any time
- Sign up / sign in / sign out — data synced to your Supabase account
- Offline-first: works without internet, syncs when signed in
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
git clone https://github.com/YOUR_USERNAME/einkaufsliste.git
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

Run the SQL schema in the Supabase SQL Editor (one time):

```sql
create table if not exists shopping_lists (
  id uuid primary key,
  owner_id uuid references auth.users not null,
  name text not null,
  is_default boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table if not exists shopping_items (
  id uuid primary key,
  list_id uuid references shopping_lists(id) on delete cascade not null,
  owner_id uuid references auth.users not null,
  name text not null,
  quantity double precision not null default 1,
  unit text not null default 'Stk.',
  category_id uuid not null,
  is_checked boolean not null default false,
  image_path text,
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table if not exists categories (
  id uuid primary key,
  owner_id uuid references auth.users not null,
  name text not null,
  color_value bigint not null,
  sort_order int not null default 0,
  is_default boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table shopping_lists enable row level security;
alter table shopping_items enable row level security;
alter table categories enable row level security;

create policy "users manage own lists" on shopping_lists
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "users manage own items" on shopping_items
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "users manage own categories" on categories
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

Also disable **Confirm email** in Supabase → Authentication → Providers → Email (required for immediate sign-in).

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

### 5. Run the app

```bash
flutter run --dart-define-from-file=.dart_defines
```

Or use the pre-configured VS Code launch config **"Einkaufsliste (debug)"** — it passes `--dart-define-from-file` automatically.

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
flutter run --dart-define-from-file=.dart_defines   # run with Supabase
flutter test                                         # run tests
flutter analyze                                      # lint
dart format lib/                                     # format
dart run build_runner build --delete-conflicting-outputs  # regen Hive adapters
```
