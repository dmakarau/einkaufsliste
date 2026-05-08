import 'app_strings.dart';

/// Keyword → default category name map for offline category prediction.
///
/// Keys are the stored German category names (from AppStrings). Values are
/// lowercase keywords. The matcher uses word-boundary checks so short words
/// like 'ei' or 'eis' don't cause false positives in longer words.
const Map<String, List<String>> kCategoryKeywords = {
  AppStrings.catObstGemuese: [
    // German
    'apfel', 'äpfel', 'birne', 'banane', 'erdbeere', 'blaubeere', 'himbeere',
    'kirsche', 'pflaume', 'pfirsich', 'mango', 'ananas', 'melone', 'traube',
    'orange',
    'zitrone',
    'limette',
    'grapefruit',
    'kiwi',
    'feige',
    'granatapfel',
    'tomate', 'gurke', 'paprika', 'karotte', 'möhre', 'kartoffel', 'brokkoli',
    'blumenkohl', 'spinat', 'salat', 'rucola', 'kohlrabi', 'zwiebel',
    'knoblauch', 'lauch', 'porree', 'zucchini', 'kürbis', 'aubergine',
    'sellerie', 'fenchel', 'pilz', 'champignon', 'avocado', 'süßkartoffel',
    'rote bete', 'rettich', 'radieschen', 'spargel', 'artischocke', 'obst',
    'gemüse', 'frucht', 'beere',
    // English
    'apple', 'pear', 'banana', 'strawberry', 'blueberry', 'raspberry',
    'cherry', 'plum', 'peach', 'mango', 'pineapple', 'melon', 'grape',
    'lemon', 'lime', 'kiwi', 'tomato', 'cucumber', 'carrot', 'potato',
    'broccoli', 'cauliflower', 'spinach', 'lettuce', 'onion', 'garlic',
    'zucchini', 'pumpkin', 'eggplant', 'celery', 'fennel', 'mushroom',
    'avocado', 'asparagus', 'vegetable', 'fruit', 'berry', 'salad',
  ],
  AppStrings.catFleisch: [
    // German
    'fleisch', 'hackfleisch', 'hack', 'hähnchen', 'hühnchen', 'pute',
    'truthahn', 'rindfleisch', 'rind', 'schweinefleisch', 'schwein',
    'lammfleisch', 'lamm', 'steak', 'schnitzel', 'kotelett', 'filet',
    'braten', 'schinken', 'salami', 'wurst', 'würstchen', 'bratwurst',
    'leberwurst', 'mortadella', 'speck', 'chorizo', 'kasseler',
    'geflügel', 'ente', 'gans',
    // English
    'meat', 'beef', 'pork', 'chicken', 'turkey', 'lamb', 'steak',
    'sausage', 'ham', 'bacon', 'salami', 'poultry', 'duck', 'goose',
    'mince', 'minced',
  ],
  AppStrings.catFischMeeresfruchte: [
    // German
    'fisch', 'lachs', 'thunfisch', 'hering', 'makrele', 'forelle', 'kabeljau',
    'heilbutt', 'seelachs', 'dorade', 'tilapia', 'fischstäbchen',
    'garnele', 'krabbe', 'hummer', 'muschel', 'tintenfisch', 'oktopus',
    'meeresfrüchte', 'räucherlachs',
    // English
    'fish', 'salmon', 'tuna', 'herring', 'mackerel', 'trout', 'cod',
    'shrimp', 'prawn', 'crab', 'lobster', 'mussel', 'squid', 'octopus',
    'seafood', 'anchovy',
  ],
  AppStrings.catMilchEier: [
    // German
    'milch', 'vollmilch', 'fettarme milch', 'butter', 'joghurt', 'quark',
    'frischkäse', 'käse', 'gouda', 'cheddar', 'parmesan', 'mozzarella',
    'feta', 'camembert', 'brie', 'emmentaler', 'sahne', 'schmand', 'kefir',
    'buttermilch', 'kondensmilch', 'hafermilch', 'mandelmilch', 'sojamilch',
    'eier', 'hühnerei',
    // English
    'milk', 'butter', 'yogurt', 'yoghurt', 'quark', 'cheese', 'cream',
    'sour cream', 'kefir', 'dairy', 'egg', 'eggs', 'oat milk', 'almond milk',
    'soy milk',
  ],
  AppStrings.catTiefkuehlkost: [
    // German
    'tiefkühl', 'tiefgefroren', 'gefrier', 'eiscreme', 'speiseeis',
    'frozen pizza', 'tiefkühlpizza', 'tiefkühlgemüse', 'tiefkühlerbsen',
    'tiefkühlfisch', 'tiefkühlfleisch', 'tiefkühlkost',
    // English
    'frozen', 'ice cream', 'gelato', 'sorbet', 'popsicle',
  ],
  AppStrings.catMuesli: [
    // German
    'müsli', 'müesli', 'haferflocken', 'cornflakes', 'granola', 'porridge',
    'reis', 'nudeln', 'spaghetti', 'penne', 'fusilli', 'linguine', 'pasta',
    'mehl', 'couscous', 'quinoa', 'linsen', 'kichererbsen', 'bohnen',
    'vollkornflocken', 'dinkel', 'buchweizen', 'grünkern', 'hirsebrei',
    // English
    'muesli', 'oats', 'oatmeal', 'cereal', 'porridge', 'granola',
    'rice', 'noodle', 'pasta', 'spaghetti', 'penne', 'flour', 'couscous',
    'quinoa', 'lentil', 'chickpea', 'bean',
  ],
  AppStrings.catBaeckereien: [
    // German
    'brot', 'brötchen', 'croissant', 'baguette', 'toast', 'toastbrot',
    'pumpernickel', 'knäckebrot', 'vollkornbrot', 'sauerteigbrot', 'bagel',
    'laugenstange', 'brezel', 'muffin', 'kuchen', 'torte', 'tarte',
    'kuchenteig', 'blätterteig', 'hefeteig', 'waffel', 'pfannkuchen',
    'crepe', 'donut', 'berliner', 'eclair', 'brioche',
    // English
    'bread', 'roll', 'bun', 'croissant', 'baguette', 'toast', 'bagel',
    'pretzel', 'muffin', 'cake', 'pastry', 'waffle', 'pancake', 'donut',
    'tart', 'brioche',
  ],
  AppStrings.catAndere: [],
  AppStrings.catGetraenke: [
    // German
    'wasser', 'mineralwasser', 'sprudelwasser', 'stilles wasser',
    'saft', 'orangensaft', 'apfelsaft', 'traubensaft', 'tomatensaft',
    'limo', 'limonade', 'cola', 'fanta', 'sprite', 'schorle', 'eistee',
    'bier', 'weizen', 'pils', 'radler', 'wein', 'rotwein', 'weißwein',
    'rosé', 'sekt', 'prosecco', 'champagner', 'gin', 'vodka', 'rum',
    'whisky', 'schnaps', 'kaffee', 'espresso', 'cappuccino', 'latte',
    'tee', 'grüntee', 'schwarztee', 'smoothie', 'energy drink', 'isotonisch',
    'getränk',
    // English
    'water', 'juice', 'lemonade', 'soda', 'cola', 'beer', 'wine',
    'champagne', 'sparkling', 'coffee', 'espresso', 'tea', 'smoothie',
    'drink', 'beverage',
  ],
  AppStrings.catKonserven: [
    // German — only single-concept keywords; "oliven" removed because it's
    // a prefix of "olivenöl" and causes false positives mid-typing
    'konserve', 'dose', 'eingelegt', 'tomatenmark', 'sauerkraut', 'kapern',
    // English
    'canned', 'tinned', 'preserved', 'pickled',
  ],
  AppStrings.catSaucen: [
    // German
    'sauce', 'soße', 'ketchup', 'mayonnaise', 'mayo', 'senf', 'sojasoße',
    'worcester', 'tabasco', 'sriracha', 'pesto', 'currypaste', 'gewürz',
    'salz', 'pfeffer', 'paprikapulver', 'zimt', 'oregano', 'basilikum',
    'thymian', 'rosmarin', 'curry', 'kurkuma', 'ingwerpulver', 'chili',
    'kreuzkümmel', 'koriander', 'muskat', 'nelken', 'lorbeer', 'vanille',
    'backpulver', 'hefe', 'würzmittel', 'brühwürfel', 'bouillon',
    // English
    'sauce', 'ketchup', 'mustard', 'mayo', 'soy sauce', 'pesto',
    'spice', 'salt', 'pepper', 'cinnamon', 'oregano', 'basil', 'thyme',
    'rosemary', 'curry', 'turmeric', 'chili', 'cumin', 'nutmeg',
    'baking powder', 'yeast', 'seasoning', 'stock cube', 'bouillon',
  ],
  AppStrings.catSnacks: [
    // German
    'chips', 'schokolade', 'gummibärchen', 'keks', 'popcorn', 'salzstange',
    'nuss', 'erdnuss', 'mandel', 'cashew', 'walnuss', 'pistazie',
    'schokoriegel', 'riegel', 'bonbon', 'karamell', 'lakritze', 'waffelkeks',
    'cracker', 'nougat', 'marmelade', 'konfitüre', 'honig', 'nutella',
    'erdnussbutter', 'zucker', 'puderzucker', 'schokoaufstrich',
    // English
    'chips', 'chocolate', 'gummy', 'cookie', 'biscuit', 'popcorn',
    'pretzel stick', 'nut', 'peanut', 'almond', 'cashew', 'walnut',
    'candy bar', 'candy', 'sweets', 'caramel', 'liquorice', 'cracker',
    'jam', 'honey', 'peanut butter', 'sugar', 'chocolate spread', 'snack',
  ],
  AppStrings.catOel: [
    // German
    'öl', 'olivenöl', 'rapsöl', 'sonnenblumenöl', 'sesamöl', 'kokosöl',
    'erdnussöl', 'leinöl', 'essig', 'weißweinessig', 'rotweinessig',
    'balsamico', 'apfelessig', 'reisessig', 'dressing', 'salatdressing',
    // English
    'oil', 'olive oil', 'rapeseed oil', 'sunflower oil', 'sesame oil',
    'coconut oil', 'vinegar', 'balsamic', 'dressing', 'salad dressing',
  ],
};
