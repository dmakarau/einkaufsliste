# Testing Rules

## What Is Tested

| Cubit | File | Notes |
|-------|------|-------|
| `ShoppingListCubit` | `test/blocs/shopping_list_cubit_test.dart` | Full method coverage |
| `ShoppingItemCubit` | `test/blocs/shopping_item_cubit_test.dart` | Full method coverage |
| `AuthCubit` | `test/blocs/auth_cubit_test.dart` | Uses `_FakeAuthRepository` — see below |
| `SettingsCubit` | `test/blocs/settings_cubit_test.dart` | Uses real Hive in temp dir — see below |

**Not unit tested:** `AuthRepository` and `SupabaseSyncService` wrap Supabase directly with no injection point. Testing them requires a live Supabase instance.

---

## Test Infrastructure (`test/helpers/fake_sync_service.dart`)

| Helper | Purpose |
|--------|---------|
| `FakeSyncService` | Captures push/delete calls; no network. Tracks `pullAllCalled` counter. |
| `MockShoppingListRepository` | Mocktail mock |
| `MockShoppingItemRepository` | Mocktail mock |
| `MockCategoryRepository` | Mocktail mock |
| `MockAuthRepository` | Mocktail mock — **do not use for `AuthCubit` tests**, see below |

---

## AuthCubit: Use `_FakeAuthRepository`, Not `MockAuthRepository`

`AuthCubit` subscribes to `authStateStream` in its constructor:
```dart
_authSub = _authRepo.authStateStream.listen(_onAuthStateChanged);
```

Mocktail enters recording mode when `when(() => authRepo.authStateStream)` is evaluated. This recording conflicts with the already-active stream subscription and throws:
```
Bad state: Cannot call `when` within a stub response
```

**Fix:** Use `_FakeAuthRepository` (defined in `auth_cubit_test.dart`). It holds a real `StreamController` and exposes test helpers:
- `emitUser(AppUser? user)` — drives `_onAuthStateChanged`
- `setCurrentUser(AppUser? user)` — controls `currentUser` getter
- `failSignInWith(String message)` / `failSignUpWith` / `failSignOutWith`

---

## Async State Assertions

For stream-driven state transitions (signIn, signOut, auth state changes), always use `expectLater` + `emitsInOrder`. **Never use microtask counting** (`Future.microtask` loops) — it is fragile under CI load and breaks silently when the cubit gains more `await` steps.

```dart
final expectation = expectLater(
  cubit.stream,
  emitsInOrder([const AuthLoading(), isA<AuthAuthenticated>()]),
);

await cubit.signIn(email: 'test@test.com', password: 'pass123');
authRepo.emitUser(const AppUser(id: '1', email: 'test@test.com'));

await expectation;
```

`expectLater` subscribes before the action starts, so it captures every emission in order. `await expectation` drains the stream until the full sequence is satisfied — no timing assumptions needed.

---

## SettingsCubit: Real Hive in a Temp Directory

`SettingsCubit` accesses `Hive.box()` directly (documented exception). Tests initialise a real Hive box — no mocking needed since the settings box stores only primitives (`bool`, `String`):

```dart
late Directory tempDir;

setUp(() async {
  tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
  await Hive.openBox<dynamic>(HiveBoxes.settings);
  cubit = SettingsCubit();
});

tearDown(() async {
  await cubit.close();
  await Hive.close();
  await tempDir.delete(recursive: true);
});
```

**Warning:** `Hive.init()` is a global singleton. Do not add Hive initialisation to other test files unless you run tests with `--concurrency=1`. Currently only `settings_cubit_test.dart` touches Hive.
