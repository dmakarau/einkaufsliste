import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/core/constants/hive_boxes.dart';
import 'package:shopping_list/data/models/category_model.dart';
import 'package:shopping_list/data/models/shopping_item_model.dart';
import 'package:shopping_list/data/services/product_search_service.dart';
import 'package:shopping_list/l10n/app_localizations.dart';
import 'package:shopping_list/presentation/blocs/shopping_item/shopping_item_cubit.dart';
import 'package:shopping_list/presentation/screens/add_item/add_item_screen.dart';

import '../helpers/fake_sync_service.dart';

CategoryModel _makeCategory() => CategoryModel(
  id: 'cat-1',
  name: 'Sonstiges',
  colorValue: 0xFF9E9E9E,
  sortOrder: 0,
  isDefault: true,
);

class _StubSearchService extends ProductSearchService {
  final List<ProductSuggestion> _localResults;
  _StubSearchService(this._localResults);

  @override
  List<ProductSuggestion> searchLocal(String query) => _localResults;

  @override
  Future<List<ProductSuggestion>?> searchRemote(String query) async => null;
}

void main() {
  late Directory tempDir;
  late MockShoppingItemRepository itemRepo;
  late ShoppingItemCubit itemCubit;

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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_widget_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingItemModelAdapter());
    }
    final catBox = await Hive.openBox<CategoryModel>(HiveBoxes.categories);
    final cat = _makeCategory();
    await catBox.put(cat.id, cat);

    itemRepo = MockShoppingItemRepository();
    when(() => itemRepo.getByListId(any())).thenReturn([]);
    when(() => itemRepo.add(any())).thenAnswer((_) async {});
    itemCubit = ShoppingItemCubit(
      itemRepository: itemRepo,
      syncService: FakeSyncService(),
    );
  });

  tearDown(() async {
    await itemCubit.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Widget buildScreen(ProductSearchService searchService) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: itemCubit,
          child: AddItemScreen(
            listId: 'test-list',
            searchService: searchService,
          ),
        ),
      ),
    );
  }

  testWidgets('suggestions appear after typing 2+ characters', (tester) async {
    final suggestions = [
      const ProductSuggestion(name: 'Milch'),
      const ProductSuggestion(name: 'Vollmilch'),
    ];
    await tester.pumpWidget(buildScreen(_StubSearchService(suggestions)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).first, 'Mi');
    await tester.pump();

    expect(find.text('Milch'), findsOneWidget);
    expect(find.text('Vollmilch'), findsOneWidget);
  });

  testWidgets('no suggestions shown for single character', (tester) async {
    final suggestions = [const ProductSuggestion(name: 'Milch')];
    await tester.pumpWidget(buildScreen(_StubSearchService(suggestions)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).first, 'M');
    await tester.pump();

    expect(find.text('Milch'), findsNothing);
  });

  testWidgets('selecting a suggestion fills the name field', (tester) async {
    final suggestions = [
      const ProductSuggestion(name: 'Butter', brand: 'Kerrygold'),
    ];
    await tester.pumpWidget(buildScreen(_StubSearchService(suggestions)));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).first, 'Bu');
    await tester.pump();

    await tester.tap(find.text('Butter'));
    await tester.pump();

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.controller?.text, equals('Kerrygold Butter'));
    expect(find.text('Butter'), findsNothing);
  });

  testWidgets(
    'image from suggestion is not saved when user edits back to < 2 chars',
    (tester) async {
      final suggestions = [
        const ProductSuggestion(
          name: 'Milch',
          brand: 'Weihenstephan',
          imageUrl: 'https://example.com/milch.jpg',
        ),
      ];
      await tester.pumpWidget(buildScreen(_StubSearchService(suggestions)));
      await tester.pump(const Duration(milliseconds: 100));

      // Select a suggestion — this captures imageUrl into _suggestionImageUrl.
      await tester.enterText(find.byType(TextField).first, 'Mi');
      await tester.pump();
      await tester.tap(find.text('Milch'));
      await tester.pump();

      // Edit back to a single character — should clear the captured image URL.
      await tester.enterText(find.byType(TextField).first, 'W');
      await tester.pump();

      // Type a new product name manually (no suggestion selected).
      await tester.enterText(find.byType(TextField).first, 'Wurst');
      await tester.pump();

      // Save — tap the TextButton whose label is the localized "Save now" string.
      await tester.tap(find.text('Save now'));
      await tester.pump();

      final captured =
          verify(() => itemRepo.add(captureAny())).captured.single
              as ShoppingItemModel;
      expect(captured.name, equals('Wurst'));
      expect(captured.imagePath, isNull);
    },
  );
}
