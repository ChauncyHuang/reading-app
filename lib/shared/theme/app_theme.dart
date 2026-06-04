import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seedColor = Color(0xFF6750A4);

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.notoSansScTextTheme(),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // Reader-specific themes
  static const readerBgColors = [
    Color(0xFFF5F0E8), // parchment
    Color(0xFFF8F8F8), // white
    Color(0xFFE8F0E8), // mint
    Color(0xFF1A1A2E), // dark
    Color(0xFF2D2D2D), // gray dark
  ];

  static const readerTextColors = [
    Color(0xFF333333), // dark text on light bg
    Color(0xFF222222),
    Color(0xFF333333),
    Color(0xFFCCCCCC), // light text on dark bg
    Color(0xFFBBBBBB),
  ];
}
