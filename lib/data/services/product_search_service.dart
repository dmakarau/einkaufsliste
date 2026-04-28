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
  List<ProductSuggestion> searchLocal(String query) {
    final q = query.toLowerCase();
    return kCommonProducts
        .where((p) => p.toLowerCase().contains(q))
        .take(8)
        .map((name) => ProductSuggestion(name: name))
        .toList();
  }

  Future<List<ProductSuggestion>?> searchRemote(String query) async {
    try {
      final uri = Uri.https('world.openfoodfacts.org', '/api/v2/search', {
        'q': query,
        'page_size': '8',
        'fields': 'product_name,brands,image_front_url',
        'lc': 'de',
      });
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'EinkaufslisteApp/1.0 (denis.makarow@gmail.com)',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final products = data['products'] as List<dynamic>? ?? [];
        final seen = <String>{};
        final results = <ProductSuggestion>[];
        for (final p in products) {
          final name = (p['product_name'] as String? ?? '').trim();
          if (name.isEmpty) continue;
          final rawBrands = (p['brands'] as String? ?? '').trim();
          final brand = rawBrands.isNotEmpty
              ? rawBrands.split(',').first.trim()
              : null;
          final imageUrl = p['image_front_url'] as String?;
          final key = '$brand|$name';
          if (seen.add(key)) {
            results.add(
              ProductSuggestion(name: name, brand: brand, imageUrl: imageUrl),
            );
          }
        }
        if (results.isNotEmpty) return results;
      } else {
        debugPrint('[ProductSearch] HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ProductSearch] error: $e');
    }
    return null;
  }
}
