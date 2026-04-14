import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/data/models/category_model.dart';
import 'package:shopping_list/data/models/shopping_item_model.dart';
import 'package:shopping_list/data/models/shopping_list_model.dart';
import 'package:shopping_list/data/repositories/auth_repository.dart';
import 'package:shopping_list/data/repositories/category_repository.dart';
import 'package:shopping_list/data/repositories/shopping_item_repository.dart';
import 'package:shopping_list/data/repositories/shopping_list_repository.dart';
import 'package:shopping_list/data/services/sync_service.dart';

/// A hand-written fake that captures sync calls for assertion in tests.
/// No network, no Supabase, no Hive required.
class FakeSyncService extends Fake implements SyncService {
  final pushedLists = <ShoppingListModel>[];
  final deletedListIds = <String>[];
  final pushedItems = <ShoppingItemModel>[];
  final deletedItemIds = <String>[];
  final sharedListIds = <String>[];
  final unsharedListIds = <String>[];
  int pullAllCalled = 0;

  @override
  bool get isAuthenticated => false;

  @override
  Future<void> pullAll({
    required ShoppingListRepository listRepo,
    required ShoppingItemRepository itemRepo,
    required CategoryRepository catRepo,
  }) async {
    pullAllCalled++;
  }

  @override
  Future<void> pushList(ShoppingListModel list) async => pushedLists.add(list);

  @override
  Future<void> deleteList(String id) async => deletedListIds.add(id);

  @override
  Future<void> pushItem(ShoppingItemModel item) async => pushedItems.add(item);

  @override
  Future<void> deleteItem(String id) async => deletedItemIds.add(id);

  @override
  Future<void> pushCategory(CategoryModel cat) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> shareList(String listId, String groupId) async =>
      sharedListIds.add(listId);

  @override
  Future<void> unshareList(String listId) async =>
      unsharedListIds.add(listId);

  @override
  void subscribeToGroupChanges(String groupId, VoidCallback onChanged) {}

  @override
  void unsubscribeGroupChanges() {}
}

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

/// NOTE: Do NOT use MockAuthRepository for AuthCubit tests.
/// AuthCubit subscribes to authStateStream in its constructor; mocktail enters
/// recording mode when that getter is stubbed via when(), which conflicts with
/// the active stream subscription and throws "Cannot call when within a stub
/// response". Use _FakeAuthRepository (defined in auth_cubit_test.dart) instead.
class MockAuthRepository extends Mock implements AuthRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}
