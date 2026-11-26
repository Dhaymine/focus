import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radius = 20;

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.blue,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
    );
    return _build(
      scheme: scheme,
      background: AppColors.darkBackground,
      muted: AppColors.darkTextMuted,
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.purple,
      secondary: AppColors.blue,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      surfaceContainerHighest: AppColors.lightSurfaceHigh,
    );
    return _build(
      scheme: scheme,
      background: AppColors.lightBackground,
      muted: AppColors.lightTextMuted,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color muted,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      textTheme: ThemeData(brightness: scheme.brightness).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      dividerColor: muted,
    );
  }
}
