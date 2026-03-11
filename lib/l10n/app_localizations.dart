import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get appName;

  /// No description provided for @navAllgemein.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get navAllgemein;

  /// No description provided for @navListen.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navListen;

  /// No description provided for @navFamilie.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navFamilie;

  /// No description provided for @navMehr.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMehr;

  /// No description provided for @allgemeineListe.
  ///
  /// In en, this message translates to:
  /// **'General List'**
  String get allgemeineListe;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listen;

  /// No description provided for @bearbeiten.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bearbeiten;

  /// No description provided for @fertig.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fertig;

  /// No description provided for @neueListeHinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'Add new list'**
  String get neueListeHinzufuegen;

  /// No description provided for @listenname.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listenname;

  /// No description provided for @hinzufuegen.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get hinzufuegen;

  /// No description provided for @abbrechen.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get abbrechen;

  /// No description provided for @familieTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familieTitle;

  /// No description provided for @familieHinweis.
  ///
  /// In en, this message translates to:
  /// **'Sign in is required to identify your data in cloud storage'**
  String get familieHinweis;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @passwort.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwort;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @mehr.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get mehr;

  /// No description provided for @appBewerten.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get appBewerten;

  /// No description provided for @einstellungen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get einstellungen;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @einstellungenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get einstellungenTitle;

  /// No description provided for @woerterbuch.
  ///
  /// In en, this message translates to:
  /// **'Dictionary with text auto-completion'**
  String get woerterbuch;

  /// No description provided for @bildschirmhelligkeit.
  ///
  /// In en, this message translates to:
  /// **'Use screen brightness'**
  String get bildschirmhelligkeit;

  /// No description provided for @kategorien.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get kategorien;

  /// No description provided for @kategorienTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get kategorienTitle;

  /// No description provided for @neueKategorie.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get neueKategorie;

  /// No description provided for @kategoriename.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get kategoriename;

  /// No description provided for @jetztSpeichern.
  ///
  /// In en, this message translates to:
  /// **'Save now'**
  String get jetztSpeichern;

  /// No description provided for @produkttitelHinweis.
  ///
  /// In en, this message translates to:
  /// **'Start typing a product title'**
  String get produkttitelHinweis;

  /// No description provided for @menge.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get menge;

  /// No description provided for @mehrOptionen.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get mehrOptionen;

  /// No description provided for @ueberProgramm.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get ueberProgramm;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @listsTile.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get listsTile;

  /// No description provided for @einheit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get einheit;

  /// No description provided for @kategorie.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get kategorie;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System (device language)'**
  String get languageSystem;

  /// No description provided for @languageDe.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageRu.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRu;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @unitStk.
  ///
  /// In en, this message translates to:
  /// **'pcs.'**
  String get unitStk;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg.'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'g.'**
  String get unitG;

  /// No description provided for @unitFl.
  ///
  /// In en, this message translates to:
  /// **'btl.'**
  String get unitFl;

  /// No description provided for @unitL.
  ///
  /// In en, this message translates to:
  /// **'L.'**
  String get unitL;

  /// No description provided for @unitPkg.
  ///
  /// In en, this message translates to:
  /// **'pkg.'**
  String get unitPkg;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml.'**
  String get unitMl;

  /// No description provided for @catObstGemuese.
  ///
  /// In en, this message translates to:
  /// **'Fruit & Veg'**
  String get catObstGemuese;

  /// No description provided for @catFleisch.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get catFleisch;

  /// No description provided for @catFischMeeresfruchte.
  ///
  /// In en, this message translates to:
  /// **'Fish & Seafood'**
  String get catFischMeeresfruchte;

  /// No description provided for @catMilchEier.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Eggs'**
  String get catMilchEier;

  /// No description provided for @catTiefkuehlkost.
  ///
  /// In en, this message translates to:
  /// **'Frozen & Ice Cream'**
  String get catTiefkuehlkost;

  /// No description provided for @catMuesli.
  ///
  /// In en, this message translates to:
  /// **'Cereals & Breakfast'**
  String get catMuesli;

  /// No description provided for @catBaeckereien.
  ///
  /// In en, this message translates to:
  /// **'Bakery & Pastry'**
  String get catBaeckereien;

  /// No description provided for @catAndere.
  ///
  /// In en, this message translates to:
  /// **'Other Food'**
  String get catAndere;

  /// No description provided for @catGetraenke.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get catGetraenke;

  /// No description provided for @catKonserven.
  ///
  /// In en, this message translates to:
  /// **'Canned Goods'**
  String get catKonserven;

  /// No description provided for @catSaucen.
  ///
  /// In en, this message translates to:
  /// **'Sauces & Spices'**
  String get catSaucen;

  /// No description provided for @catSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks & Sweets'**
  String get catSnacks;

  /// No description provided for @catOel.
  ///
  /// In en, this message translates to:
  /// **'Oil, Vinegar & Dressings'**
  String get catOel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {email}!'**
  String welcomeUser(String email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
