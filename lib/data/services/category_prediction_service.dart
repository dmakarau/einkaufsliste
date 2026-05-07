import '../../core/constants/category_keywords.dart';
import '../../core/constants/openfoodfacts_category_map.dart';
import '../models/category_model.dart';

class CategoryPredictionService {
  /// Predicts a category ID from a typed query using keyword matching.
  ///
  /// Exact and word-boundary matches score 2; prefix and compound-suffix
  /// matches score 1. This lets a perfect match ("tomate" → catObst) beat a
  /// false-positive prefix match ("tomatensaft".startsWith("tomate") → catGetraenke).
  ///
  /// Returns null when no confident match is found — never falls back to a
  /// default, leaving the existing screen default intact.
  String? predictFromQuery(String query, List<CategoryModel> categories) {
    final q = _normalize(query);
    if (q.length < 2) return null;

    final nameToId = _buildNameToId(categories);
    String? bestCategory;
    int bestScore = 0;

    for (final entry in kCategoryKeywords.entries) {
      if (entry.value.isEmpty) continue;
      int score = 0;
      for (final keyword in entry.value) {
        score += _matchScore(q, keyword);
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      } else if (score == bestScore && score > 0) {
        bestCategory = null;
      }
    }

    if (bestCategory == null || bestScore == 0) return null;
    return nameToId[bestCategory];
  }

  /// Predicts a category ID from Open Food Facts `categories_tags`.
  ///
  /// Tags must already have the `en:` prefix stripped. Returns the first
  /// match from the specificity-ordered [kOpenFoodFactsCategoryMap].
  String? predictFromOpenFoodFactsTags(
    List<String> tags,
    List<CategoryModel> categories,
  ) {
    if (tags.isEmpty) return null;
    final tagSet = tags.toSet();
    final nameToId = _buildNameToId(categories);

    for (final (tag, categoryName) in kOpenFoodFactsCategoryMap) {
      if (tagSet.contains(tag)) {
        return nameToId[categoryName];
      }
    }
    return null;
  }

  Map<String, String> _buildNameToId(List<CategoryModel> categories) {
    return {for (final c in categories) c.name: c.id};
  }

  // Normalizes to lowercase ASCII: ä→a, ö→o, ü→u so that "olivenol" and
  // "olivenöl" both normalize to "olivenol" and match each other.
  String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e');
  }

  /// Returns a match score for [keyword] against [query] (0 = no match).
  ///
  /// Scoring:
  /// - 2 pts: exact match or standalone word-boundary match (high confidence).
  /// - 1 pt:  prefix match (user still typing) or German compound-suffix match.
  ///
  /// Higher scores let an exact match ("tomate") beat a false-positive prefix
  /// match from a longer keyword in another category ("tomatensaft").
  ///
  /// Notably absent: query.startsWith(keyword) — that would match "bierschinken"
  /// against "bier" (German compound modifier false positive).
  int _matchScore(String query, String keyword) {
    final k = _normalize(keyword);
    if (k.length < 2) return 0;

    // Exact match.
    if (query == k) return 2;

    // Standalone word: keyword surrounded by non-alphanumeric characters in query.
    final pattern = RegExp(
      r'(?<![a-z0-9])' + RegExp.escape(k) + r'(?![a-z0-9])',
    );
    if (pattern.hasMatch(query)) return 2;

    // Prefix match: keyword starts with query (user still typing, e.g. "milc" → "milch").
    if (k.startsWith(query)) return 1;

    // German compound suffix: keyword (≥ 5 chars) is the head noun at end of word
    // (e.g. "Eisbergsalat" → "salat", "Vollmilch" → "milch").
    if (k.length >= 5 && query.endsWith(k)) return 1;

    return 0;
  }
}
