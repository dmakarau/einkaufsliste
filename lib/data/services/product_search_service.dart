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
  static const _germanyTag = 'en:germany';

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
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'EinkaufslisteApp/1.0 (denis.makarow@gmail.com)',
            },
          )
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
          final brandsList = p['brands'] as List<dynamic>? ?? [];
          final brand = brandsList.isNotEmpty
              ? brandsList.first.toString().trim()
              : null;
          final imageUrl = p['image_front_url'] as String?;
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
