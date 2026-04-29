import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/data/services/product_search_service.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  late _MockHttpClient mockClient;
  late ProductSearchService service;

  setUp(() {
    mockClient = _MockHttpClient();
    service = ProductSearchService(client: mockClient);
    registerFallbackValue(Uri());
  });

  Map<String, dynamic> makeResponse(List<Map<String, dynamic>> hits) =>
      {'hits': hits};

  http.Response ok(Map<String, dynamic> body) =>
      http.Response(jsonEncode(body), 200);

  Map<String, dynamic> hit({
    required String name,
    String? brands,
    String? imageUrl,
    List<String> countryTags = const ['en:germany'],
  }) =>
      {
        'product_name': name,
        'brands': brands,
        'image_front_url': imageUrl,
        'countries_tags': countryTags,
      };

  group('searchLocal', () {
    test('returns matching products case-insensitively', () {
      final results = service.searchLocal('milch');
      expect(results.map((s) => s.name), contains('Milch'));
    });

    test('returns at most 8 results', () {
      final results = service.searchLocal('a');
      expect(results.length, lessThanOrEqualTo(8));
    });
  });

  group('searchRemote', () {
    test('parses comma-separated brands string correctly', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => ok(
          makeResponse([
            hit(name: 'Vollmilch', brands: 'Weihenstephan, Bauer'),
            hit(name: 'Fettarme Milch', brands: 'Weihenstephan'),
            hit(name: 'Bio-Milch', brands: 'Alnatura'),
            hit(name: 'H-Milch', brands: 'Ja'),
          ]),
        ),
      );

      final results = await service.searchRemote('Milch');
      expect(results, isNotNull);
      // Only the first brand before the comma should be used
      expect(results!.first.brand, equals('Weihenstephan'));
    });

    test('returns null when fewer than 4 Germany-tagged results', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => ok(
          makeResponse([
            hit(name: 'Butter', brands: 'Kerrygold'),
            hit(name: 'Butter mild', brands: 'Meggle'),
          ]),
        ),
      );

      final results = await service.searchRemote('Butter');
      expect(results, isNull);
    });

    test('filters out products not tagged en:germany', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => ok(
          makeResponse([
            hit(
              name: 'French Baguette',
              brands: 'SomeBrand',
              countryTags: ['en:france'],
            ),
            hit(name: 'Brot', brands: 'Mestemacher'),
            hit(name: 'Vollkornbrot', brands: 'Mestemacher'),
            hit(name: 'Toastbrot', brands: 'Harry'),
            hit(name: 'Roggenbrot', brands: 'Lieken'),
          ]),
        ),
      );

      final results = await service.searchRemote('Brot');
      expect(results, isNotNull);
      expect(results!.any((s) => s.name == 'French Baguette'), isFalse);
    });

    test('skips products with empty name', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => ok(
          makeResponse([
            hit(name: '', brands: 'SomeBrand'),
            hit(name: 'Joghurt', brands: 'Danone'),
            hit(name: 'Fruchtjoghurt', brands: 'Danone'),
            hit(name: 'Naturjoghurt', brands: 'Müller'),
            hit(name: 'Joghurt mild', brands: 'Ehrmann'),
          ]),
        ),
      );

      final results = await service.searchRemote('Joghurt');
      expect(results, isNotNull);
      expect(results!.any((s) => s.name.isEmpty), isFalse);
    });

    test('returns null on HTTP error', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 500));

      final results = await service.searchRemote('Milch');
      expect(results, isNull);
    });

    test('returns null on network exception', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('network error'));

      final results = await service.searchRemote('Milch');
      expect(results, isNull);
    });

    test('brand is null when brands field is empty', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => ok(
          makeResponse([
            hit(name: 'Eigenmarke Milch', brands: ''),
            hit(name: 'Eigenmarke Joghurt', brands: ''),
            hit(name: 'Eigenmarke Käse', brands: ''),
            hit(name: 'Eigenmarke Butter', brands: ''),
          ]),
        ),
      );

      final results = await service.searchRemote('Eigen');
      expect(results, isNotNull);
      expect(results!.every((s) => s.brand == null), isTrue);
    });
  });
}
