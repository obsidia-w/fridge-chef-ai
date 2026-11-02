import 'package:flutter/material.dart';

/// '냉장고 셰프 AI' 디자인 시스템 테마 및 컬러 토큰 (DESIGN.md 준수)
/// - Figma 레퍼런스 (Food Delivery UI Kit & JavaGem Coffee Shop Mobile App)
/// - ui-skills (baseline-ui, fixing-accessibility, fixing-motion-performance)
class AppTheme {
  AppTheme._();

  // Hero & Dark Surfaces (JavaGem Coffee Shop Reference)
  static const Color espressoCharcoal = Color(0xFF1C1917);
  static const Color espressoMuted = Color(0xFF292524);

  // Warm Accent Colors (Terracotta / Caramel & Food Delivery Coral)
  static const Color terracotta = Color(0xFFC67C4E);
  static const Color terracottaDark = Color(0xFF9A5830);
  static const Color terracottaLight = Color(0xFFF9F2ED);

  // Fresh Herb Green (Can Make Now / Verified Status)
  static const Color primaryGreen = Color(0xFF15803D);
  static const Color primaryGreenDark = Color(0xFF166534);
  static const Color primaryGreenLight = Color(0xFFDCFCE7);

  // Canvas & Card Surfaces
  static const Color warmWhite = Color(0xFFF9F6F0);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFEAE4DC);

  // Warning & Missing Ingredient Accents
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentAmberDark = Color(0xFFB45309);

  // Danger & Allergy Filter Accents
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerRedLight = Color(0xFFFEE2E2);

  // Typography Colors
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFFA8A29E);

  /// baseline-ui 규칙: 숫자(칼로리, 그램, 인분, 시간, 퍼센트)가 변해도 레이아웃이 흔들리지 않도록 고정폭 숫자 적용
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: terracotta,
      surface: surfaceWhite,
      error: dangerRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: warmWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceWhite,
        selectedColor: terracottaLight,
        checkmarkColor: terracottaDark,
        side: const BorderSide(color: borderSubtle),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: terracotta, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceWhite,
        indicatorColor: terracottaLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: terracottaDark,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          );
        }),
      ),
    );
  }
}
