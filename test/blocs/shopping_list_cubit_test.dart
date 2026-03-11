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
}
