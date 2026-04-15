# Einkaufsliste — Claude Development Guide

## Project Overview
A German shopping list app for iOS/Android built with Flutter. Features multiple shopping lists, colour-coded categories, offline-first Hive storage, per-account Supabase cloud sync, and family group sharing (create group, invite by email, share lists, real-time sync).

## Key Commands
```bash
# Run the app (secrets required via dart-define)
flutter run --dart-define-from-file=.dart_defines

# Run tests
flutter test

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
Supabase credentials are passed at build time via `--dart-define-from-file=.dart_defines`.
`.dart_defines` is gitignored — copy from `.dart_defines.example` and fill in real values.
`lib/core/constants/supabase_config.dart` reads them via `String.fromEnvironment`.

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
└── main.dart           # Hive init, seed data, BlocProviders, Supabase init
```

**Data flow:** Cubits read from repositories (Hive). After every write, Cubits call `SyncService` fire-and-forget (implementation: `SupabaseSyncService`). On sign-in, `AuthCubit` calls `pullAll()` which replaces Hive with Supabase data.

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

**Auth sign-out behaviour:** `AuthCubit._onAuthStateChanged(null)` clears lists and items but intentionally does **not** clear categories. On iOS, the Supabase client fires a null auth event before restoring the session, which would empty the category box before re-seeding could complete. Categories are always overwritten by `pullAll()` on the next sign-in, so leaving them in place is safe.

## Testing

Tests live in `test/blocs/` (Cubit unit tests) and `test/helpers/` (shared fakes).
Covered: `ShoppingListCubit`, `ShoppingItemCubit`, `AuthCubit`, `SettingsCubit`.
Not covered: `AuthRepository`, `SupabaseSyncService`, `FamilyGroupRepository`, `FamilyCubit` (wrap Supabase directly, no injection point).

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

**Realtime:** `shopping_lists`, `shopping_items`, and `family_group_members` are in the Supabase realtime publication. `ShoppingListCubit` subscribes to group changes when the user is in a group.

**Storage:** bucket `shopping-item-images` (public). Images are uploaded by `SupabaseSyncService.pushItem()` when `imagePath` is a local file path; the local path is replaced with the public URL before the DB upsert.
