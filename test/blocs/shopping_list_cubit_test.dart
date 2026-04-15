import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/data/models/shopping_list_model.dart';
import 'package:shopping_list/presentation/blocs/shopping_list/shopping_list_cubit.dart';
import 'package:shopping_list/presentation/blocs/shopping_list/shopping_list_state.dart';

import '../helpers/fake_sync_service.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      ShoppingListModel(id: 'x', name: 'x', isDefault: false, createdAt: DateTime(2024)),
    );
  });

  late MockShoppingListRepository listRepo;
  late MockShoppingItemRepository itemRepo;
  late FakeSyncService sync;
  late ShoppingListCubit cubit;

  setUp(() {
    listRepo = MockShoppingListRepository();
    itemRepo = MockShoppingItemRepository();
    sync = FakeSyncService();
    cubit = ShoppingListCubit(
      listRepository: listRepo,
      itemRepository: itemRepo,
      categoryRepository: MockCategoryRepository(),
      syncService: sync,
    );
  });

  tearDown(() => cubit.close());

  group('loadLists', () {
    test('emits ShoppingListLoaded with repo data', () {
      when(() => listRepo.getAll()).thenReturn([]);

      cubit.loadLists();

      expect(cubit.state, const ShoppingListLoaded([]));
    });

    test('emits ShoppingListError when repo throws', () {
      when(() => listRepo.getAll()).thenThrow(Exception('Hive error'));

      cubit.loadLists();

      expect(cubit.state, isA<ShoppingListError>());
    });
  });

  group('addList', () {
    test('writes to repo and pushes to sync', () async {
      when(() => listRepo.add(any())).thenAnswer((_) async {});
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.addList('Wocheneinkauf');

      verify(() => listRepo.add(any())).called(1);
      expect(sync.pushedLists.length, 1);
      expect(sync.pushedLists.first.name, 'Wocheneinkauf');
    });
  });

  group('renameList', () {
    test('updates repo and pushes to sync', () async {
      final list = ShoppingListModel(
        id: 'list-1',
        name: 'Alt',
        isDefault: false,
        createdAt: DateTime(2024),
      );
      when(() => listRepo.getById('list-1')).thenReturn(list);
      when(() => listRepo.update(any())).thenAnswer((_) async {});
      when(() => listRepo.getAll()).thenReturn([list]);

      await cubit.renameList('list-1', 'Neu');

      verify(() => listRepo.update(any())).called(1);
      expect(sync.pushedLists.length, 1);
      expect(sync.pushedLists.first.name, 'Neu');
    });

    test('is no-op when list not found', () async {
      when(() => listRepo.getById('missing')).thenReturn(null);

      await cubit.renameList('missing', 'Neu');

      verifyNever(() => listRepo.update(any()));
      expect(sync.pushedLists, isEmpty);
    });
  });

  group('deleteList', () {
    test('deletes from repo and sync for non-default list', () async {
      final list = ShoppingListModel(
        id: 'list-1',
        name: 'Testliste',
        isDefault: false,
        createdAt: DateTime(2024),
      );
      when(() => listRepo.getById('list-1')).thenReturn(list);
      when(() => itemRepo.deleteByListId('list-1')).thenAnswer((_) async {});
      when(() => listRepo.delete('list-1')).thenAnswer((_) async {});
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.deleteList('list-1');

      verify(() => listRepo.delete('list-1')).called(1);
      expect(sync.deletedListIds, contains('list-1'));
    });

    test('is no-op for default list', () async {
      final defaultList = ShoppingListModel(
        id: 'list-1',
        name: 'Allgemeine Liste',
        isDefault: true,
        createdAt: DateTime(2024),
      );
      when(() => listRepo.getById('list-1')).thenReturn(defaultList);

      await cubit.deleteList('list-1');

      expect(sync.deletedListIds, isEmpty);
    });

    test('is no-op when list not found', () async {
      when(() => listRepo.getById('missing')).thenReturn(null);

      await cubit.deleteList('missing');

      expect(sync.deletedListIds, isEmpty);
    });
  });

  group('shareList', () {
    test('updates repo and syncs share', () async {
      final list = ShoppingListModel(
        id: 'list-1',
        name: 'Test',
        isDefault: false,
        createdAt: DateTime(2024),
      );
      when(() => listRepo.getById('list-1')).thenReturn(list);
      when(() => listRepo.update(any())).thenAnswer((_) async {});
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.shareList('list-1', 'group-1');

      verify(() => listRepo.update(any())).called(1);
      expect(sync.sharedListIds, contains('list-1'));
    });

    test('is no-op when list not found', () async {
      when(() => listRepo.getById('missing')).thenReturn(null);

      await cubit.shareList('missing', 'group-1');

      verifyNever(() => listRepo.update(any()));
      expect(sync.sharedListIds, isEmpty);
    });
  });

  group('unshareList', () {
    test('updates repo and syncs unshare', () async {
      final list = ShoppingListModel(
        id: 'list-1',
        name: 'Test',
        isDefault: false,
        createdAt: DateTime(2024),
        familyGroupId: 'group-1',
      );
      when(() => listRepo.getById('list-1')).thenReturn(list);
      when(() => listRepo.update(any())).thenAnswer((_) async {});
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.unshareList('list-1');

      verify(() => listRepo.update(any())).called(1);
      expect(sync.unsharedListIds, contains('list-1'));
    });

    test('is no-op when list not found', () async {
      when(() => listRepo.getById('missing')).thenReturn(null);

      await cubit.unshareList('missing');

      verifyNever(() => listRepo.update(any()));
      expect(sync.unsharedListIds, isEmpty);
    });
  });

  group('syncFromRemote', () {
    test('is no-op when not authenticated', () async {
      // sync.isAuthenticated defaults to false
      await cubit.syncFromRemote();

      expect(sync.pullAllCalled, 0);
      expect(cubit.state, isA<ShoppingListLoading>());
    });

    test('calls pullAll and emits ShoppingListLoaded when authenticated', () async {
      sync.isAuthenticated = true;
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.syncFromRemote();

      expect(sync.pullAllCalled, 1);
      expect(cubit.state, const ShoppingListLoaded([]));
    });

    test('still emits ShoppingListLoaded when pullAll throws', () async {
      sync.isAuthenticated = true;
      sync.shouldThrowOnPullAll = true;
      when(() => listRepo.getAll()).thenReturn([]);

      await cubit.syncFromRemote();

      expect(cubit.state, const ShoppingListLoaded([]));
    });
  });
}
