# Einkaufsliste — Claude Development Guide

## Project Overview
A German shopping list app for iOS/Android built with Flutter. Features multiple shopping lists, colour-coded categories, offline-first Hive storage, and per-account Supabase cloud sync. Family sharing schema is in place but not yet wired to the UI.

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
| `ShoppingListModel` | 0 | id, name, isDefault, createdAt |
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

## Supabase Tables
`shopping_lists`, `shopping_items`, `categories` — all with `owner_id uuid references auth.users` and RLS enabled. Schema also includes `family_groups` / `family_group_members` for future family sharing (no app UI yet).

**Storage:** bucket `shopping-item-images` (public). Images are uploaded by `SupabaseSyncService.pushItem()` when `imagePath` is a local file path; the local path is replaced with the public URL before the DB upsert.
