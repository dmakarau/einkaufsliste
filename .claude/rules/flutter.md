# Flutter Rules

## Widget Guidelines
- Prefer `StatelessWidget` for all screens; use Cubits for state
- Use `const` constructors wherever possible
- Extract reusable UI pieces into `lib/presentation/widgets/`
- Keep `build()` methods under ~80 lines; extract sub-widgets if longer
- Do NOT use `setState` in screens — use Cubit instead

## BLoC / Cubit Pattern
- One Cubit per feature area (not per screen)
- States must extend `Equatable` and override `props`
- Emit sealed states: use `sealed class` or a union pattern (loading / loaded / error)
- Provide Cubits at the top level in `main.dart` using `MultiBlocProvider`
- Access cubits in widgets: `context.read<MyCubit>().doSomething()` (not `BlocProvider.of`)

```dart
// Good
context.read<ShoppingListCubit>().addList('My List');

// Good
BlocBuilder<ShoppingListCubit, ShoppingListState>(
  builder: (context, state) { ... },
)

// Bad — business logic in widget
void _onTap() {
  final box = Hive.box('lists');
  box.put(...); // NO — this belongs in a repository + cubit
}
```

## Navigation (go_router)
- Use `context.go('/path')` for tab switching (replaces history)
- Use `context.push('/path')` for pushing onto the stack (back button works)
- Pass complex objects as `extra:`, not query params
- Modal sheets: use `showModalBottomSheet`, not a named route

## Hive Storage
- Always `await` Hive operations in repository methods
- Repository methods are async and return `Future<T>`
- Do not call Hive directly in Cubits — always go through repositories

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
