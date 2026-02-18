import 'package:flutter/material.dart';

import '../../domain/models/app_settings.dart';

ThemeData buildAppTheme(AppSettings settings) {
  final colorScheme = settings.highContrast
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF000000),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF00695C),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFB00020),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
        )
      : ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F9D8B),
          brightness: Brightness.light,
        );

  final textTheme = ThemeData.light().textTheme.apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: settings.highContrast
        ? Colors.white
        : const Color(0xFFF5FAF7),
    textTheme: textTheme.copyWith(
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: 20,
        height: settings.dyslexiaMode ? 1.6 : 1.35,
        letterSpacing: settings.dyslexiaMode ? 1.2 : 0.3,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: 18,
        height: settings.dyslexiaMode ? 1.6 : 1.3,
        letterSpacing: settings.dyslexiaMode ? 1.1 : 0.2,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: settings.dyslexiaMode ? 1.3 : 0.4,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: settings.dyslexiaMode ? 1.5 : 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: settings.highContrast
              ? Colors.black
              : colorScheme.primary.withValues(alpha: 0.16),
          width: settings.highContrast ? 2 : 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: settings.highContrast ? Colors.white : const Color(0xFFEAF7F3),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: colorScheme.primaryContainer,
      labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: settings.highContrast
              ? Colors.black
              : colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: settings.highContrast ? Colors.black : const Color(0xFF146C5B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
