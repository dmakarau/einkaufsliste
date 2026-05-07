import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/core/constants/app_strings.dart';
import 'package:shopping_list/data/models/category_model.dart';
import 'package:shopping_list/data/services/category_prediction_service.dart';

List<CategoryModel> _allCategories() {
  final names = [
    AppStrings.catObstGemuese,
    AppStrings.catFleisch,
    AppStrings.catFischMeeresfruchte,
    AppStrings.catMilchEier,
    AppStrings.catTiefkuehlkost,
    AppStrings.catMuesli,
    AppStrings.catBaeckereien,
    AppStrings.catAndere,
    AppStrings.catGetraenke,
    AppStrings.catKonserven,
    AppStrings.catSaucen,
    AppStrings.catSnacks,
    AppStrings.catOel,
  ];
  return [
    for (var i = 0; i < names.length; i++)
      CategoryModel(
        id: 'id-$i',
        name: names[i],
        colorValue: 0xFF000000,
        sortOrder: i,
        isDefault: true,
      ),
  ];
}

String _idFor(String name, List<CategoryModel> cats) =>
    cats.firstWhere((c) => c.name == name).id;

void main() {
  late CategoryPredictionService service;
  late List<CategoryModel> cats;

  setUp(() {
    service = CategoryPredictionService();
    cats = _allCategories();
  });

  group('predictFromQuery', () {
    test('returns null for empty string', () {
      expect(service.predictFromQuery('', cats), isNull);
    });

    test('returns null for single character', () {
      expect(service.predictFromQuery('M', cats), isNull);
    });

    test('milch → Milchprodukte und Eier', () {
      expect(
        service.predictFromQuery('Milch', cats),
        equals(_idFor(AppStrings.catMilchEier, cats)),
      );
    });

    test('partial typing "milc" → Milchprodukte und Eier', () {
      expect(
        service.predictFromQuery('milc', cats),
        equals(_idFor(AppStrings.catMilchEier, cats)),
      );
    });

    test('vollmilch → Milchprodukte und Eier', () {
      expect(
        service.predictFromQuery('Vollmilch', cats),
        equals(_idFor(AppStrings.catMilchEier, cats)),
      );
    });

    test('wein → Getränke', () {
      expect(
        service.predictFromQuery('Wein', cats),
        equals(_idFor(AppStrings.catGetraenke, cats)),
      );
    });

    test('bier → Getränke', () {
      expect(
        service.predictFromQuery('Bier', cats),
        equals(_idFor(AppStrings.catGetraenke, cats)),
      );
    });

    test('Bierschinken → Fleisch (not Getränke)', () {
      // "bier" must not match inside "bierschinken"
      expect(
        service.predictFromQuery('Bierschinken', cats),
        equals(_idFor(AppStrings.catFleisch, cats)),
      );
    });

    test('Eisbergsalat → Obst und Gemüse (not Tiefkühlkost)', () {
      // "eis" is not in the keyword table; "salat" should win
      expect(
        service.predictFromQuery('Eisbergsalat', cats),
        equals(_idFor(AppStrings.catObstGemuese, cats)),
      );
    });

    test('tomate → Obst und Gemüse', () {
      expect(
        service.predictFromQuery('Tomate', cats),
        equals(_idFor(AppStrings.catObstGemuese, cats)),
      );
    });

    test('olivenöl → Öl, Essig und Salat-Dressings', () {
      expect(
        service.predictFromQuery('Olivenöl', cats),
        equals(_idFor(AppStrings.catOel, cats)),
      );
    });

    test('diacritic-free "olivenol" also → Öl-Kategorie', () {
      expect(
        service.predictFromQuery('olivenol', cats),
        equals(_idFor(AppStrings.catOel, cats)),
      );
    });

    test('schokolade → Snacks', () {
      expect(
        service.predictFromQuery('Schokolade', cats),
        equals(_idFor(AppStrings.catSnacks, cats)),
      );
    });

    test('lachs → Fisch und Meeresfrüchte', () {
      expect(
        service.predictFromQuery('Lachs', cats),
        equals(_idFor(AppStrings.catFischMeeresfruchte, cats)),
      );
    });

    test('brot → Bäckereien und Konditoreien', () {
      expect(
        service.predictFromQuery('Brot', cats),
        equals(_idFor(AppStrings.catBaeckereien, cats)),
      );
    });

    test('missing category returns null gracefully', () {
      // Remove Getränke from the list — prediction should return null, not crash.
      final reduced = cats
          .where((c) => c.name != AppStrings.catGetraenke)
          .toList();
      expect(service.predictFromQuery('Wein', reduced), isNull);
    });
  });

  group('predictFromOpenFoodFactsTags', () {
    test('wines tag → Getränke', () {
      expect(
        service.predictFromOpenFoodFactsTags([
          'wines',
          'alcoholic-beverages',
          'beverages',
        ], cats),
        equals(_idFor(AppStrings.catGetraenke, cats)),
      );
    });

    test('canned-fishes beats canned-foods → Fisch', () {
      expect(
        service.predictFromOpenFoodFactsTags([
          'canned-fishes',
          'canned-foods',
          'seafood',
        ], cats),
        equals(_idFor(AppStrings.catFischMeeresfruchte, cats)),
      );
    });

    test('dairies → Milchprodukte und Eier', () {
      expect(
        service.predictFromOpenFoodFactsTags(['dairies', 'milks'], cats),
        equals(_idFor(AppStrings.catMilchEier, cats)),
      );
    });

    test('empty tags → null', () {
      expect(service.predictFromOpenFoodFactsTags([], cats), isNull);
    });

    test('unknown tags only → null', () {
      expect(
        service.predictFromOpenFoodFactsTags([
          'fr:boissons',
          'de:getraenke',
        ], cats),
        isNull,
      );
    });

    test('missing category returns null gracefully', () {
      final reduced = cats
          .where((c) => c.name != AppStrings.catGetraenke)
          .toList();
      expect(service.predictFromOpenFoodFactsTags(['wines'], reduced), isNull);
    });
  });
}
