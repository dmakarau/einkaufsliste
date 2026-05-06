import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // UI
  static const Color primary = Color(0xFF007AFF); // iOS blue
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFD1D1D6);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color checkboxBorder = Color(0xFF007AFF);

  // Category colors (matching screenshots)
  static const Color catObstGemuese = Color(0xFF4A7C4E);
  static const Color catFleisch = Color(0xFFB03A2E);
  static const Color catFischMeeresfruchte = Color(0xFFE07B7B);
  static const Color catMilchEier = Color(0xFFD4B896);
  static const Color catTiefkuehlkost = Color(0xFF5B9BD5);
  static const Color catMuesli = Color(0xFF8B6914);
  static const Color catBaeckereien = Color(0xFFB8864E);
  static const Color catAndere = Color(0xFF4A4A4A);
  static const Color catGetraenke = Color(0xFF6B3A2A);
  static const Color catKonserven = Color(0xFF8B7355);
  static const Color catSaucen = Color(0xFF8B1A1A);
  static const Color catSnacks = Color(0xFFD4A017);
  static const Color catOel = Color(0xFF7B2D2D);

  static const List<Color> categoryColors = [
    catObstGemuese,
    catFleisch,
    catFischMeeresfruchte,
    catMilchEier,
    catTiefkuehlkost,
    catMuesli,
    catBaeckereien,
    catAndere,
    catGetraenke,
    catKonserven,
    catSaucen,
    catSnacks,
    catOel,
  ];
}
