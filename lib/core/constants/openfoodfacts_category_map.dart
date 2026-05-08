import 'app_strings.dart';

/// Open Food Facts taxonomy tag → default category name.
///
/// Tags are stored without the `en:` prefix (stripped by ProductSearchService).
/// Order matters: more-specific tags come first so that a product tagged with
/// both `canned-fishes` and `canned-foods` resolves to Fisch, not Konserven.
/// The matcher returns the first hit from this ordered list.
const List<(String, String)> kOpenFoodFactsCategoryMap = [
  // ── Beverages ──────────────────────────────────────────────────────────────
  ('mineral-waters', AppStrings.catGetraenke),
  ('fruit-juices', AppStrings.catGetraenke),
  ('fruit-nectars', AppStrings.catGetraenke),
  ('sodas', AppStrings.catGetraenke),
  ('waters', AppStrings.catGetraenke),
  ('wines', AppStrings.catGetraenke),
  ('beers', AppStrings.catGetraenke),
  ('coffees', AppStrings.catGetraenke),
  ('teas', AppStrings.catGetraenke),
  ('hot-beverages', AppStrings.catGetraenke),
  ('plant-based-beverages', AppStrings.catGetraenke),
  ('alcoholic-beverages', AppStrings.catGetraenke),
  ('non-alcoholic-beverages', AppStrings.catGetraenke),
  ('beverages', AppStrings.catGetraenke),
  ('drinks', AppStrings.catGetraenke),

  // ── Dairy & eggs ───────────────────────────────────────────────────────────
  ('milks', AppStrings.catMilchEier),
  ('butters', AppStrings.catMilchEier),
  ('cheeses', AppStrings.catMilchEier),
  ('yogurts', AppStrings.catMilchEier),
  ('fermented-milk-products', AppStrings.catMilchEier),
  ('creams', AppStrings.catMilchEier),
  ('eggs', AppStrings.catMilchEier),
  ('dairies', AppStrings.catMilchEier),

  // ── Meat ───────────────────────────────────────────────────────────────────
  ('poultry', AppStrings.catFleisch),
  ('sausages', AppStrings.catFleisch),
  ('hams', AppStrings.catFleisch),
  ('salamis', AppStrings.catFleisch),
  ('prepared-meats', AppStrings.catFleisch),
  ('meats-and-their-products', AppStrings.catFleisch),
  ('meats', AppStrings.catFleisch),

  // ── Fish & seafood ─────────────────────────────────────────────────────────
  ('canned-fishes', AppStrings.catFischMeeresfruchte),
  ('smoked-fishes', AppStrings.catFischMeeresfruchte),
  ('fishes', AppStrings.catFischMeeresfruchte),
  ('crustaceans', AppStrings.catFischMeeresfruchte),
  ('seafood', AppStrings.catFischMeeresfruchte),

  // ── Frozen ─────────────────────────────────────────────────────────────────
  ('ice-creams-and-sorbets', AppStrings.catTiefkuehlkost),
  ('frozen-desserts', AppStrings.catTiefkuehlkost),
  ('frozen-foods', AppStrings.catTiefkuehlkost),

  // ── Bakery ─────────────────────────────────────────────────────────────────
  ('breads', AppStrings.catBaeckereien),
  ('cakes', AppStrings.catBaeckereien),
  ('breakfast-pastries', AppStrings.catBaeckereien),
  ('pastries', AppStrings.catBaeckereien),

  // ── Breakfast / cereals ────────────────────────────────────────────────────
  ('mueslis', AppStrings.catMuesli),
  ('breakfast-cereals', AppStrings.catMuesli),
  ('breakfasts', AppStrings.catMuesli),
  ('pastas', AppStrings.catMuesli),
  ('rices', AppStrings.catMuesli),
  ('flours', AppStrings.catMuesli),
  ('legumes', AppStrings.catMuesli),
  ('cereals-and-their-products', AppStrings.catMuesli),

  // ── Canned (after fish-specific tags) ──────────────────────────────────────
  ('canned-vegetables', AppStrings.catKonserven),
  ('canned-fruits', AppStrings.catKonserven),
  ('canned-legumes', AppStrings.catKonserven),
  ('canned-foods', AppStrings.catKonserven),
  ('preserved-foods', AppStrings.catKonserven),

  // ── Fresh produce ──────────────────────────────────────────────────────────
  ('fresh-fruits', AppStrings.catObstGemuese),
  ('fresh-vegetables', AppStrings.catObstGemuese),
  ('fruits-and-vegetables-based-foods', AppStrings.catObstGemuese),
  ('fruits', AppStrings.catObstGemuese),
  ('vegetables', AppStrings.catObstGemuese),
  ('salads', AppStrings.catObstGemuese),

  // ── Oils & vinegars ────────────────────────────────────────────────────────
  ('olive-oils', AppStrings.catOel),
  ('oils', AppStrings.catOel),
  ('vinegars', AppStrings.catOel),
  ('salad-dressings', AppStrings.catOel),
  ('fats', AppStrings.catOel),
  ('vegetable-fats', AppStrings.catOel),

  // ── Sauces & condiments ────────────────────────────────────────────────────
  ('mustards', AppStrings.catSaucen),
  ('ketchups', AppStrings.catSaucen),
  ('mayonnaises', AppStrings.catSaucen),
  ('culinary-spices', AppStrings.catSaucen),
  ('herbs', AppStrings.catSaucen),
  ('sauces', AppStrings.catSaucen),
  ('condiments', AppStrings.catSaucen),
  ('salt', AppStrings.catSaucen),

  // ── Snacks & sweets ────────────────────────────────────────────────────────
  ('chocolates', AppStrings.catSnacks),
  ('chocolate-products', AppStrings.catSnacks),
  ('confectioneries', AppStrings.catSnacks),
  ('candies', AppStrings.catSnacks),
  ('chips-and-fries', AppStrings.catSnacks),
  ('biscuits-and-cakes', AppStrings.catSnacks),
  ('sweet-snacks', AppStrings.catSnacks),
  ('salty-snacks', AppStrings.catSnacks),
  ('spreads', AppStrings.catSnacks),
  ('snacks', AppStrings.catSnacks),
];
