import 'package:flutter/material.dart';

/// GoCollab brand palette — inspired by Google's four brand colors.
///
/// These are used *intentionally as accents* (per design spec) rather than
/// dominating the UI: white/light-gray surfaces carry the interface, while
/// blue/green/yellow/red highlight specific semantic states.
abstract final class AppColors {
  // ---- Google-inspired brand colors ----
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed = Color(0xFFEA4335);

  // ---- Neutral surfaces ----
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLightGray = Color(0xFFF8F9FA);
  static const Color surfaceBorder = Color(0xFFE8EAED);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textDisabled = Color(0xFF9AA0A6);

  // ---- Semantic aliases (keep naming close to product spec) ----
  static const Color primary = googleBlue;
  static const Color success = googleGreen; // career / completed / confirmed
  static const Color highlight = googleYellow; // events / pending / featured
  static const Color alert = googleRed; // deadlines / warnings / partnerships

  /// The four brand hues, in Google's canonical order — used to build the
  /// flowing prismatic gradients throughout the premium UI surfaces.
  static const List<Color> prismaticSpectrum = [
    googleBlue,
    googleGreen,
    googleYellow,
    googleRed,
  ];

  static const MaterialColor primarySwatch = MaterialColor(0xFF4285F4, {
    50: Color(0xFFE8F0FE),
    100: Color(0xFFC6DAFC),
    200: Color(0xFFA0C3FA),
    300: Color(0xFF7AABF8),
    400: Color(0xFF5A98F6),
    500: Color(0xFF4285F4),
    600: Color(0xFF3B7DE8),
    700: Color(0xFF3272D9),
    800: Color(0xFF2A68CB),
    900: Color(0xFF1C55AF),
  });
}
