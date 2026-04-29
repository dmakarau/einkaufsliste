import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/common_products.dart';

class ProductSuggestion {
  const ProductSuggestion({required this.name, this.brand, this.imageUrl});

  final String name;
  final String? brand;
  final String? imageUrl;

  String get displayName =>
      (brand != null && brand!.isNotEmpty) ? '${brand!} $name' : name;
}

class ProductSearchService {
  ProductSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _germanyTag = 'en:germany';

  void close() => _client.close();

  List<ProductSuggestion> searchLocal(String query) {
    final q = query.toLowerCase();
    return kCommonProducts
        .where((p) => p.toLowerCase().contains(q))
        .take(8)
        .map((name) => ProductSuggestion(name: name))
        .toList();
  }

  // Uses Search-a-licious — Elasticsearch-backed, more stable than the main API.
  // Fetches 100 results and filters client-side to products tagged as sold in
  // Germany (en:germany), since Search-a-licious ignores server-side country filters.
  Future<List<ProductSuggestion>?> searchRemote(String query) async {
    try {
      final uri = Uri.https('search.openfoodfacts.org', '/search', {
        'q': query,
        'page_size': '100',
        'fields': 'product_name,brands,image_front_url,countries_tags',
      });
      final response = await _client
          .get(uri, headers: {'User-Agent': 'EinkaufslisteApp/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final hits = data['hits'] as List<dynamic>? ?? [];
        final seen = <String>{};
        final results = <ProductSuggestion>[];
        for (final p in hits) {
          final tags = (p['countries_tags'] as List<dynamic>? ?? [])
              .cast<String>();
          if (!tags.contains(_germanyTag)) continue;
          final name = (p['product_name'] as String? ?? '').trim();
          if (name.isEmpty) continue;
          final brandsField = p['brands'];
          final brand = brandsField is String && brandsField.isNotEmpty
              ? brandsField.split(',').first.trim()
              : null;
          final imageUrl = p['image_front_url'] is String
              ? p['image_front_url'] as String
              : null;
          final key = '$brand|$name';
          if (seen.add(key) && results.length < 8) {
            results.add(
              ProductSuggestion(name: name, brand: brand, imageUrl: imageUrl),
            );
          }
        }
        if (results.length >= 4) return results;
      } else {
        debugPrint('[ProductSearch] HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ProductSearch] error: $e');
    }
    return null;
  }
}
