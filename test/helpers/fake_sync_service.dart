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
}

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}
