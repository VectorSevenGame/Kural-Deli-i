import 'package:flutter/material.dart';

/// Stitch'ten gelen "Warm Haven" tasarim sistemi.
///
/// Renkler tohumdan turetilmiyor, tasarimdaki degerler birebir yaziliyor.
abstract final class AppColors {
  static const Color primary = Color(0xFFC85A32); // terracotta
  static const Color secondary = Color(0xFF5E7C60); // adaçayı yeşili
  static const Color tertiary = Color(0xFFD88B35); // amber
  static const Color neutral = Color(0xFF2B2623); // koyu kahve

  // Açık tema
  static const Color lightBackground = Color(0xFFFDF8F4);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFF6EDE6);
  static const Color lightPrimaryContainer = Color(0xFFFBE4D8);
  static const Color lightOnPrimaryContainer = Color(0xFF9E4423);
  static const Color lightSecondaryContainer = Color(0xFFDDE8DD);
  static const Color lightOnSecondaryContainer = Color(0xFF3A5740);
  static const Color lightTertiaryContainer = Color(0xFFFBE7CC);
  static const Color lightOnTertiaryContainer = Color(0xFF8A5411);
  static const Color lightMutedText = Color(0xFF8A7F78);
  static const Color lightOutline = Color(0xFFE8DCD2);
  static const Color error = Color(0xFFC0392B);
  static const Color lightErrorContainer = Color(0xFFFBDDD8);
  static const Color lightOnErrorContainer = Color(0xFF8E2A1E);

  // Koyu tema
  static const Color darkBackground = Color(0xFF1A1613);
  static const Color darkCard = Color(0xFF241F1B);
  static const Color darkMuted = Color(0xFF2E2823);
}

abstract final class AppTheme {
  static const String fontFamily = 'PlusJakartaSans';

  /// Kartlarin ve panellerin kose yaricapi.
  static const double radiusCard = 20;
  static const double radiusField = 14;

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightOnPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightSecondaryContainer,
      onSecondaryContainer: AppColors.lightOnSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.lightTertiaryContainer,
      onTertiaryContainer: AppColors.lightOnTertiaryContainer,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.lightErrorContainer,
      onErrorContainer: AppColors.lightOnErrorContainer,
      surface: AppColors.lightBackground,
      onSurface: AppColors.neutral,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.lightCard,
      surfaceContainer: AppColors.lightMuted,
      surfaceContainerHigh: AppColors.lightMuted,
      surfaceContainerHighest: AppColors.lightMuted,
      onSurfaceVariant: AppColors.lightMutedText,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutline,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE8825A),
      onPrimary: Color(0xFF3A1409),
      primaryContainer: Color(0xFF7A3419),
      onPrimaryContainer: Color(0xFFFFDCCC),
      secondary: Color(0xFF9CBC9E),
      onSecondary: Color(0xFF1B3020),
      secondaryContainer: Color(0xFF3A5740),
      onSecondaryContainer: Color(0xFFDDE8DD),
      tertiary: Color(0xFFE9B072),
      onTertiary: Color(0xFF452A05),
      tertiaryContainer: Color(0xFF6B4413),
      onTertiaryContainer: Color(0xFFFBE7CC),
      error: Color(0xFFE98B7E),
      onError: Color(0xFF4A120A),
      errorContainer: Color(0xFF7A2418),
      onErrorContainer: Color(0xFFFBDDD8),
      surface: AppColors.darkBackground,
      onSurface: Color(0xFFF2E9E2),
      surfaceContainerLowest: Color(0xFF130F0D),
      surfaceContainerLow: AppColors.darkCard,
      surfaceContainer: AppColors.darkMuted,
      surfaceContainerHigh: Color(0xFF362F29),
      surfaceContainerHighest: Color(0xFF3F3730),
      onSurfaceVariant: Color(0xFFB5A79D),
      outline: Color(0xFF4A413A),
      outlineVariant: Color(0xFF39322C),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontWeight: FontWeight.w800, height: 1.15),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, height: 1.2),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(height: 1.45),
        bodyMedium: TextStyle(height: 1.45),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? Colors.white : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primary,
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
