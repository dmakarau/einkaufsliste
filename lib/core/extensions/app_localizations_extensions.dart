import 'package:shopping_list/l10n/app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  String localizeCategory(String storedName) {
    switch (storedName) {
      case 'Obst und Gemüse':
        return catObstGemuese;
      case 'Fleisch':
        return catFleisch;
      case 'Fisch und Meeresfrüchte':
        return catFischMeeresfruchte;
      case 'Milchprodukte und Eier':
        return catMilchEier;
      case 'Tiefkühlkost und Eiscreme':
        return catTiefkuehlkost;
      case 'Müsli und Frühstückskost':
        return catMuesli;
      case 'Bäckereien und Konditoreien':
        return catBaeckereien;
      case 'Andere Lebensmittel':
        return catAndere;
      case 'Getränke':
        return catGetraenke;
      case 'Konserven':
        return catKonserven;
      case 'Saucen, Gewürze und Würzmittel':
        return catSaucen;
      case 'Snacks, Chips und Süßigkeiten':
        return catSnacks;
      case 'Öl, Essig und Salat-Dressings':
        return catOel;
      default:
        return storedName;
    }
  }

  String localizeUnit(String storedUnit) {
    switch (storedUnit) {
      case 'Stk.':
        return unitStk;
      case 'kg.':
        return unitKg;
      case 'g.':
        return unitG;
      case 'Fl.':
        return unitFl;
      case 'L.':
        return unitL;
      case 'Pkg.':
        return unitPkg;
      case 'ml.':
        return unitMl;
      default:
        return storedUnit;
    }
  }
}
