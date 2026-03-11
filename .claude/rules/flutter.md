# Flutter Rules

## Widget Guidelines
- Prefer `StatelessWidget` for screens with no local state
- Use `StatefulWidget` when the screen needs local ephemeral UI state (search bar open/closed, edit mode toggle, `TextEditingController`, focus management)
- `setState` is acceptable for purely local UI state; business/domain state always goes in a Cubit
- Use `const` constructors wherever possible
- Extract reusable UI pieces into `lib/presentation/widgets/`
- Keep `build()` methods under ~80 lines; extract sub-widgets if longer

## BLoC / Cubit Pattern
- One Cubit per feature area (not per screen)
- States must extend `Equatable` and override `props`
- Emit sealed states: use `sealed class` or a union pattern (loading / loaded / error)
- Provide Cubits at the top level in `main.dart` using `MultiBlocProvider`
- Access cubits in widgets: `context.read<MyCubit>().doSomething()` (not `BlocProvider.of`)

```dart
// Good — business action via Cubit
context.read<ShoppingListCubit>().addList('My List');

// Good — rebuild on state change
BlocBuilder<ShoppingListCubit, ShoppingListState>(
  builder: (context, state) { ... },
)

// Good — local UI toggle
setState(() => _isEditing = !_isEditing);

// Bad — business logic in widget
void _onTap() {
  final box = Hive.box('lists');
  box.put(...); // belongs in a repository + cubit
}
```

## Supabase Sync Pattern
- After every local mutation (add / update / delete), call the corresponding `SupabaseSyncService` method fire-and-forget using `unawaited()`:
  ```dart
  await _repo.add(item);
  unawaited(_sync.pushItem(item)); // non-blocking; UI doesn't wait
  ```
- Never `await` sync calls in Cubits — they must not block state updates or UI

## Navigation (go_router)
- Use `context.go('/path')` for tab switching (replaces history)
- Use `context.push('/path')` for pushing onto the stack (back button works)
- Pass complex objects as `extra:`, not query params
- Modal sheets: use `showModalBottomSheet`, not a named route

## Data Access in Screens
- For mutations, always go through a Cubit
- For read-only display data (item counts, single lookups), screens may call repositories directly via `context.read<SomeRepository>()` — this avoids unnecessary Cubits for trivial reads
- `SettingsCubit` is a documented exception: it reads/writes the Hive settings box directly (simple key-value, no domain logic)

## Hive Storage
- Always `await` Hive operations in repository methods
- Repository methods are async and return `Future<T>`
- Do not call Hive directly in Cubits, except `SettingsCubit` which manages the settings box as a documented exception

## Styling
- Use `Theme.of(context)` for colors and text styles — never hardcode hex in widgets
- Exception: category color strips use `AppColors` constants directly
- Use `SizedBox` for spacing, not `Padding` with one side
- Dividers between list items: use `Divider(height: 1, indent: 16)`

## Naming
- Screens: `*Screen` (e.g., `AllgemeinScreen`)
- Cubits: `*Cubit` (e.g., `ShoppingListCubit`)
- States: `*State` (e.g., `ShoppingListState`)
- Models: `*Model` (e.g., `ShoppingItemModel`)
- Repositories: `*Repository` (e.g., `CategoryRepository`)
- Widgets: descriptive noun (e.g., `ShoppingItemTile`, `CategoryColorStrip`)
