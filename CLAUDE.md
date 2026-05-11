# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Einkaufsliste — Claude Development Guide

## Project Overview
A German shopping list app for iOS/Android built with Flutter. Features multiple shopping lists, colour-coded categories, offline-first Hive storage, per-account Supabase cloud sync, and family group sharing (create group, invite by email, share lists, real-time sync).

## Key Commands
```bash
# Run the app (secrets required via dart-define)
flutter run --dart-define-from-file=.dart_defines

# Run all tests
flutter test

# Run a single test file
flutter test test/blocs/auth_cubit_test.dart

# Run Hive-touching tests with concurrency=1 (settings_cubit, add_item_screen)
# Hive.init() is a global singleton — parallel test isolates corrupt each other
flutter test --concurrency=1 test/blocs/settings_cubit_test.dart test/widgets/add_item_screen_autocomplete_test.dart

# Lint
flutter analyze

# Format
dart format lib/

# Regenerate Hive adapters (run after any @HiveType model change)
dart run build_runner build --delete-conflicting-outputs

# Regenerate l10n (run after editing any .arb file)
flutter gen-l10n
```

## Secrets
All credentials are passed at build time via `--dart-define-from-file=.dart_defines`.
`.dart_defines` is gitignored — copy from `.dart_defines.example` and fill in real values.
`lib/core/constants/supabase_config.dart` reads them via `String.fromEnvironment`.

| Key | Description |
|-----|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |
| `GOOGLE_WEB_CLIENT_ID` | Web OAuth client ID (from Google Cloud Console) |
| `GOOGLE_IOS_CLIENT_ID` | iOS OAuth client ID (from Google Cloud Console) |

`.env.supabase` is a separate gitignored file used by the Supabase CLI and the pre-commit drift hook:
```
SUPABASE_DB_PASSWORD=your_db_password
```

## Supabase Schema Management
The `supabase/` folder contains the CLI config and all migrations. The baseline is `supabase/migrations/20260511200647_remote_schema.sql`. Requires Docker Desktop running.

```bash
# Apply all pending migrations to the remote database
supabase db push --password $SUPABASE_DB_PASSWORD

# Pull schema changes made directly in the Supabase dashboard
supabase db pull --password $SUPABASE_DB_PASSWORD

# Generate a named diff (preferred for surgical changes)
supabase db diff --password $SUPABASE_DB_PASSWORD -f describe_the_change

# List migration history
supabase migration list --password $SUPABASE_DB_PASSWORD
```

**After making a schema change in the Supabase dashboard:** run `/supabase-sync` — Claude detects the diff, writes a named migration file, and commits it.

**Pre-commit hook:** every `git commit` automatically runs `supabase db diff`. If uncommitted schema changes are detected, the commit is blocked and `/supabase-sync` is suggested.

## Architecture
Feature-first clean architecture. See `.claude/rules/architecture.md` for layer rules and `.claude/rules/flutter.md` for Flutter/Cubit conventions.

```
lib/
├── core/               # Theme, router, constants, l10n extensions
├── data/
│   ├── models/         # @HiveType annotated models + transient models (e.g. AppUser)
│   ├── repositories/   # Hive CRUD (local source of truth)
│   └── services/       # SyncService interface + SupabaseSyncService implementation
└── presentation/
    ├── blocs/          # Cubits + States
    ├── screens/        # One folder per screen
    └── widgets/        # Shared widgets
└── main.dart           # Hive init, seed data, BlocProviders, Supabase init; _AppContent lifecycle observer
```

**Data flow:** Cubits read from repositories (Hive). After every write, Cubits call `SyncService` fire-and-forget (implementation: `SupabaseSyncService`). On sign-in, `AuthCubit` calls `pullAll()` which replaces Hive with Supabase data. `ShoppingListCubit.syncFromRemote()` provides the same pull on app resume (`AppLifecycleState.resumed` via `_AppContent` in `main.dart`) and on pull-to-refresh in `AllgemeinScreen` / `ListDetailScreen`. `FamilyCubit.loadGroupStatus()` is also called on resume, guarded by `AuthAuthenticated` check (resume fires before the session is established during OAuth redirects, so the guard prevents a stale-JWT query from emitting `FamilyError`).

**`AuthAuthenticated.isSynced` flag:** `AuthAuthenticated` carries an `isSynced: bool` field (default `false`). `checkAuthStatus()` emits `isSynced: false` (session restored from cache, no remote pull yet). `_onAuthStateChanged` emits `isSynced: true` after `pullAll()` completes. The `BlocListener` in `main.dart` reacts to both the type-change transition *and* the `false → true` transition so `loadLists()` is always called after `pullAll()` — this fixes the Google cold-start race where `TOKEN_REFRESHED` arrived after `checkAuthStatus()` had already emitted `AuthAuthenticated`.

## Tech Stack
| Concern | Package |
|---------|---------|
| State management | `flutter_bloc` (Cubit pattern) |
| Local storage | `hive_flutter` |
| Hive code gen | `hive_generator` + `build_runner` |
| Cloud backend | `supabase_flutter` |
| Navigation | `go_router` |
| i18n | Flutter gen-l10n (`intl`) |
| Value equality | `equatable` |
| Unique IDs | `uuid` |
| Image picker | `image_picker` |
| Network image cache | `cached_network_image` |
| File paths | `path_provider` + `path` |
| HTTP client | `http` |
| Google Sign-In | `google_sign_in` |
| SVG rendering | `flutter_svg` (Google G logo inline SVG in `familie_screen.dart`) |
| Test mocking | `mocktail` (dev) |

## Data Models
| Model | Hive typeId | Fields |
|-------|------------|--------|
| `ShoppingListModel` | 0 | id, name, isDefault, createdAt, familyGroupId (HiveField 4, nullable) |
| `ShoppingItemModel` | 1 | id, listId, name, quantity, unit, categoryId, isChecked, imagePath, createdAt |
| `CategoryModel` | 2 | id, name, colorValue (int), sortOrder, isDefault |

Box names → `lib/core/constants/hive_boxes.dart`: `shopping_lists`, `shopping_items`, `categories`, `settings`

## Internationalization
- ARB files: `lib/l10n/app_en.arb` (template), `app_de.arb`, `app_ru.arb`
- Generated: `lib/l10n/app_localizations*.dart` (do not edit)
- Shorthand: `context.l10n` via `lib/core/extensions/build_context_extensions.dart`
- Language stored in Hive settings box under key `'languageCode'`; empty string = device locale
- To add a string: add to all 3 ARB files → `flutter gen-l10n`

## Screen Map
| Tab | Screen | Path |
|-----|--------|------|
| Allgemein | AllgemeinScreen | `/allgemein` |
| Listen | ListenScreen | `/listen` |
| Listen > detail | ListDetailScreen | `/listen/:listId` |
| Familie | FamilieScreen | `/familie` |
| Mehr | MehrScreen | `/mehr` |
| Settings | SettingsScreen | `/mehr/settings` |
| Categories | CategoriesScreen | `/mehr/settings/categories` |
| Info | AboutScreen | `/mehr/info` |

Modal screens (e.g. AddItemScreen) use `showModalBottomSheet`, not a route.

**AddItemScreen** reads categories directly via `CategoryRepository()` (not `context.read`) and subscribes to `CategoryRepository.watch()` so the picker updates reactively if seeding completes after the sheet opens. This is intentional — the modal builder's context is outside the app's `RepositoryProvider` tree.

**Product autocomplete in AddItemScreen:** `ProductSearchService` (`lib/data/services/product_search_service.dart`) provides two-phase autocomplete. `searchLocal()` filters `kCommonProducts` (`lib/core/constants/common_products.dart`) synchronously for instant results. `searchRemote()` queries the Open Food Facts Search-a-licious API (`https://search.openfoodfacts.org/search`) and returns `ProductSuggestion` objects with `name`, `brand`, `imageUrl`, and `categoryTags` (Open Food Facts `categories_tags` with the `en:` prefix stripped). The screen shows local results immediately on each keystroke and upgrades to API results after a 400 ms debounce. `ProductSearchService` accepts an optional `http.Client` for testing and is instantiated directly in the widget (same pattern as `CategoryRepository()`). `AddItemScreen` accepts an optional `searchService` parameter for widget testing.

**Category prediction in AddItemScreen:** `CategoryPredictionService` (`lib/data/services/category_prediction_service.dart`) auto-selects the category picker using two signals: (1) keyword matching against `kCategoryKeywords` (`lib/core/constants/category_keywords.dart`) — fires on every keystroke; (2) Open Food Facts tag matching against `kOpenFoodFactsCategoryMap` (`lib/core/constants/openfoodfacts_category_map.dart`) — fires when the user taps a product suggestion. Scoring: exact/word-boundary matches = 2 pts, prefix/compound-suffix matches = 1 pt. Prediction is suppressed once `_userPickedCategory` is set (user tapped the picker manually). Returns null on uncertainty — never overrides the existing selection with a guess. Renamed/deleted categories are handled gracefully (null returned, no crash).

**Auth sign-out behaviour:** `AuthCubit._onAuthStateChanged(null)` clears lists and items but intentionally does **not** clear categories. On iOS, the Supabase client fires a null auth event before restoring the session, which would empty the category box before re-seeding could complete. Categories are always overwritten by `pullAll()` on the next sign-in, so leaving them in place is safe.

**Google Sign-In:** Uses `google_sign_in` v7 native flow (no browser redirect). `GoogleSignIn.instance.initialize()` is called in `main()` with `serverClientId` (Web client ID) and `clientId` (iOS client ID). `AuthRepository.signInWithGoogle()` calls `authenticate()`, extracts the ID token, then calls `supabase.auth.signInWithIdToken()`. The existing `_onAuthStateChanged` stream handles everything after that. `signOut()` also calls `GoogleSignIn.instance.signOut()` to revoke the Google session. Platform files: `ios/Runner/GoogleService-Info.plist` (iOS) and `android/app/google-services.json` (Android) — both committed; they contain public OAuth client IDs and an Android API key restricted to the app's package name + SHA-1 certificate fingerprint and to Identity Toolkit API + Token Service API only. Supabase dashboard requires **Skip nonce checks** enabled on the Google provider (iOS SDK omits the nonce).

## Testing

Tests live in `test/blocs/` (Cubit unit tests), `test/services/` (service unit tests), `test/widgets/` (widget tests), and `test/helpers/` (shared fakes).
Covered: `ShoppingListCubit`, `ShoppingItemCubit`, `AuthCubit`, `SettingsCubit`, `ProductSearchService`, `CategoryPredictionService`, `AddItemScreen` (autocomplete + category prediction behaviour).
Not covered: `AuthRepository`, `SupabaseSyncService`, `FamilyGroupRepository`, `FamilyCubit` (wrap Supabase directly, no injection point). Specifically, `FamilyCubit`'s Realtime paths (`_refreshMembers`, `subscribeToMemberChanges`, `subscribeToInvites`) have no unit tests — they require a live Supabase channel and are verified on-device only.

See `.claude/rules/testing.md` for test infrastructure, the `MockAuthRepository` gotcha, async assertion patterns, and Hive test setup.

## Supabase Tables

All tables have RLS enabled. See `.claude/rules/supabase.md` for RLS policy details and the full invite flow.

| Table | Key columns |
|-------|-------------|
| `shopping_lists` | `id`, `owner_id`, `family_group_id` (nullable FK→`family_groups`), `name`, `is_default`, `created_at`, `updated_at` |
| `shopping_items` | `id`, `list_id` (FK→`shopping_lists`), `owner_id`, `name`, `quantity`, `unit`, `category_id`, `is_checked`, `image_path`, `created_at`, `updated_at` |
| `categories` | `id`, `owner_id`, `family_group_id` (nullable, reserved), `name`, `color_value`, `sort_order`, `is_default`, `created_at`, `updated_at` |
| `family_groups` | `id`, `owner_id`, `name`, `created_at` |
| `family_group_members` | `id`, `group_id` (FK→`family_groups`), `user_id` (nullable until accepted), `email`, `role` (`admin`/`member`), `status` (`pending`/`accepted`), `invited_by`, `created_at` |

**Sharing model:** A list is shared with a group by setting `family_group_id`. RLS lets all accepted members read and write items in shared lists. Owner controls INSERT/UPDATE/DELETE on the list record itself.

**Realtime:** `shopping_lists`, `shopping_items`, and `family_group_members` are in the Supabase realtime publication. `ShoppingListCubit` subscribes to `shopping_lists` changes (filtered by `family_group_id`) when the user is in a group. Item changes propagate via a Postgres trigger (`shopping_items_touch_list`) that bumps `shopping_lists.updated_at` — the app does not subscribe to `shopping_items` Realtime events directly (Supabase cannot reliably evaluate the complex group-membership RLS policy at Realtime event time). `FamilyCubit` subscribes to `family_group_members` via two channels: `'members_$groupId'` (admin/member list updates — INSERT/UPDATE/DELETE) and `'invites_$uid'` (incoming invite notification for users not yet in a group — INSERT only). For `family_group_members` Realtime to work, three Supabase-side requirements must be met — see `.claude/rules/supabase.md` for the required SQL.

**Storage:** bucket `shopping-item-images` (public). Images are uploaded by `SupabaseSyncService.pushItem()` when `imagePath` is a local file path; the local path is replaced with the public URL before the DB upsert.
