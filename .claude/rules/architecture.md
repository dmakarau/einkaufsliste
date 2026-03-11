# Architecture Rules

## Layer Responsibilities

### `lib/core/`
- **Only** shared, app-wide code: theme, router, constants, l10n extensions
- No business logic, no Hive calls, no state management
- `app_colors.dart` — category colours + palette constants
- `hive_boxes.dart` — box name string constants (prevent typos)
- `app_theme.dart` — single `ThemeData` used in `MaterialApp`
- `app_router.dart` — complete `GoRouter` config
- `build_context_extensions.dart` — `context.l10n` shorthand

### `lib/data/`
- **Models**: annotated with `@HiveType` / `@HiveField`. Plain data classes.
- **Repositories**: async CRUD methods over Hive boxes. Local source of truth. No Supabase calls.
- **Services**: `SupabaseSyncService` owns all Supabase table I/O. Called from Cubits fire-and-forget.
- No Flutter UI imports in this layer

### `lib/presentation/`
- **blocs/**: Cubits + States only. May call repositories and `SupabaseSyncService`. No direct Hive access.
- **screens/**: One folder per screen. Prefer `StatelessWidget`; use `StatefulWidget` only when local ephemeral state is needed (e.g. text controllers, search toggle).
- **widgets/**: Reusable widgets. No Cubit dependencies unless clearly justified.

## Dependency Direction
```
presentation → blocs → repositories (Hive) + services (Supabase)
presentation → core (theme, colors, router, l10n)
```
- Lower layers must NOT import from higher layers
- `data/` must not import from `presentation/`

## Adding a New Feature (checklist)
1. Add model in `data/models/` with `@HiveType`
2. Add repository in `data/repositories/`
3. Add sync methods to `SupabaseSyncService` if cloud persistence is needed
4. Add Cubit + State in `presentation/blocs/<feature>/`
5. Add screen(s) in `presentation/screens/<feature>/`
6. Register Cubit in `MultiBlocProvider` in `main.dart`
7. Add route in `app_router.dart`
8. Add strings to all three ARB files → `flutter gen-l10n`
9. Run `dart run build_runner build --delete-conflicting-outputs`

## What Goes Where (quick reference)
| Thing | Location |
|-------|----------|
| UI string | `lib/l10n/app_*.arb` (all 3 files) |
| Category colour | `core/constants/app_colors.dart` |
| Hive box name | `core/constants/hive_boxes.dart` |
| Route path | `core/router/app_router.dart` |
| Hive model | `data/models/` |
| Hive CRUD | `data/repositories/` |
| Supabase I/O | `data/services/supabase_sync_service.dart` |
| State + logic | `presentation/blocs/` |
| Screen widget | `presentation/screens/` |
| Shared widget | `presentation/widgets/` |
