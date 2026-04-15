import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/data/models/shopping_item_model.dart';
import 'package:shopping_list/presentation/blocs/shopping_item/shopping_item_cubit.dart';
import 'package:shopping_list/presentation/blocs/shopping_item/shopping_item_state.dart';

import '../helpers/fake_sync_service.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      ShoppingItemModel(
        id: 'x',
        listId: 'x',
        name: 'x',
        quantity: 1,
        unit: 'Stk.',
        categoryId: 'x',
        isChecked: false,
        createdAt: DateTime(2024),
      ),
    );
  });

  late MockShoppingItemRepository repo;
  late FakeSyncService sync;
  late ShoppingItemCubit cubit;

  setUp(() {
    repo = MockShoppingItemRepository();
    sync = FakeSyncService();
    cubit = ShoppingItemCubit(itemRepository: repo, syncService: sync);
  });

  tearDown(() => cubit.close());

  group('loadItems', () {
    test('emits ShoppingItemLoaded with repo data', () {
      when(() => repo.getByListId('list-1')).thenReturn([]);

      cubit.loadItems('list-1');

      final state = cubit.state as ShoppingItemLoaded;
      expect(state.listId, 'list-1');
      expect(state.items, isEmpty);
    });

    test('emits ShoppingItemError when repo throws', () {
      when(() => repo.getByListId('list-1')).thenThrow(Exception('Hive error'));

      cubit.loadItems('list-1');

      expect(cubit.state, isA<ShoppingItemError>());
    });
  });

  group('clearItems', () {
    test('emits empty ShoppingItemLoaded', () {
      cubit.clearItems();

      final state = cubit.state as ShoppingItemLoaded;
      expect(state.items, isEmpty);
      expect(state.listId, '');
    });
  });

  group('addItem', () {
    test('writes to repo and pushes to sync', () async {
      when(() => repo.add(any())).thenAnswer((_) async {});
      when(() => repo.getByListId('list-1')).thenReturn([]);

      await cubit.addItem(listId: 'list-1', name: 'Milch', categoryId: 'cat-1');

      verify(() => repo.add(any())).called(1);
      expect(sync.pushedItems.length, 1);
      expect(sync.pushedItems.first.name, 'Milch');
    });

    test('forwards imagePath to repo and sync', () async {
      when(() => repo.add(any())).thenAnswer((_) async {});
      when(() => repo.getByListId('list-1')).thenReturn([]);

      await cubit.addItem(
        listId: 'list-1',
        name: 'Käse',
        categoryId: 'cat-1',
        imagePath: '/data/user/0/item_images/123.jpg',
      );

      final captured =
          verify(() => repo.add(captureAny())).captured.single
              as ShoppingItemModel;
      expect(captured.imagePath, '/data/user/0/item_images/123.jpg');
      expect(
        sync.pushedItems.first.imagePath,
        '/data/user/0/item_images/123.jpg',
      );
    });
  });

  group('deleteItem', () {
    test('removes from repo and syncs delete', () async {
      final item = ShoppingItemModel(
        id: 'item-1',
        listId: 'list-1',
        name: 'Brot',
        quantity: 1,
        unit: 'Stk.',
        categoryId: 'cat-1',
        isChecked: false,
        createdAt: DateTime(2024),
      );
      when(() => repo.getByListId('list-1')).thenReturn([item]);
      when(() => repo.delete('item-1')).thenAnswer((_) async {});

      cubit.loadItems('list-1');
      await cubit.deleteItem('item-1');

      verify(() => repo.delete('item-1')).called(1);
      expect(sync.deletedItemIds, contains('item-1'));
    });

    test('is no-op when state is not loaded', () async {
      // Initial state is ShoppingItemLoading — deleteItem should do nothing.
      await cubit.deleteItem('item-1');

      expect(sync.deletedItemIds, isEmpty);
    });
  });

  group('toggleChecked', () {
    test('flips isChecked and pushes to sync', () async {
      final item = ShoppingItemModel(
        id: 'item-1',
        listId: 'list-1',
        name: 'Eier',
        quantity: 6,
        unit: 'Stk.',
        categoryId: 'cat-1',
        isChecked: false,
        createdAt: DateTime(2024),
      );
      when(() => repo.getByListId('list-1')).thenReturn([item]);
      when(() => repo.update(any())).thenAnswer((_) async {});

      cubit.loadItems('list-1');
      await cubit.toggleChecked('item-1');

      verify(() => repo.update(any())).called(1);
      expect(sync.pushedItems.length, 1);
      expect(sync.pushedItems.first.isChecked, isTrue);
    });
  });

  group('updateItem', () {
    test('writes to repo, pushes to sync, and reloads state', () async {
      final original = ShoppingItemModel(
        id: 'item-1',
        listId: 'list-1',
        name: 'Butter',
        quantity: 1,
        unit: 'Stk.',
        categoryId: 'cat-1',
        isChecked: false,
        createdAt: DateTime(2024),
      );
      final updated = ShoppingItemModel(
        id: 'item-1',
        listId: 'list-1',
        name: 'Butter (gesalzen)',
        quantity: 2,
        unit: 'Stk.',
        categoryId: 'cat-1',
        isChecked: false,
        createdAt: DateTime(2024),
      );
      // Initial load returns original; after update the repo returns updated.
      when(() => repo.getByListId('list-1')).thenReturn([original]);
      when(() => repo.update(any())).thenAnswer((_) async {});

      cubit.loadItems('list-1');

      // Stub the reload (called inside updateItem) to return the updated item.
      when(() => repo.getByListId('list-1')).thenReturn([updated]);
      await cubit.updateItem(updated);

      verify(() => repo.update(any())).called(1);
      expect(sync.pushedItems.first.name, 'Butter (gesalzen)');
      expect(sync.pushedItems.first.quantity, 2);

      final state = cubit.state as ShoppingItemLoaded;
      expect(state.items.first.name, 'Butter (gesalzen)');
    });

    test('persists to repo and sync even when no list is loaded', () async {
      final item = ShoppingItemModel(
        id: 'item-1',
        listId: 'list-1',
        name: 'Käse',
        quantity: 1,
        unit: 'Stk.',
        categoryId: 'cat-1',
        isChecked: false,
        createdAt: DateTime(2024),
      );
      when(() => repo.update(any())).thenAnswer((_) async {});

      // No loadItems call — _currentListId stays null.
      await cubit.updateItem(item);

      verify(() => repo.update(any())).called(1);
      expect(sync.pushedItems.first.name, 'Käse');
      // State must not change — no list is active to reload.
      expect(cubit.state, isA<ShoppingItemLoading>());
    });
  });
}
