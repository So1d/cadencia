import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema do Cadência: brutalista dark, raio 2px, sem sombra, borda dura.
abstract class AppTheme {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(2));
  static const BorderSide borderSide =
      BorderSide(color: AppColors.border, width: 1);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
      primaryContainer: AppColors.primaryHover,
      onPrimaryContainer: AppColors.textLight,
      secondary: AppColors.primaryHover,
      onSecondary: AppColors.textLight,
      error: AppColors.danger,
      onError: AppColors.textLight,
      surface: AppColors.bgSecondary,
      onSurface: AppColors.textMain,
      outline: AppColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      fontFamily: null, // system-ui por padrão, igual o CSS
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: borderSide),
        titleTextStyle: TextStyle(
          fontSize: 1.15 * 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgTertiary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          side: borderSide,
          borderRadius: radius,
        ),
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.primary),
          foregroundColor: WidgetStatePropertyAll(AppColors.textLight),
          elevation: WidgetStatePropertyAll(0),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(side: borderSide, borderRadius: radius),
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(borderSide),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(
          borderSide: borderSide,
          borderRadius: radius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: borderSide,
          borderRadius: radius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderFocus),
          borderRadius: radius,
        ),
        labelStyle: TextStyle(color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        contentTextStyle: TextStyle(color: AppColors.textMain, fontSize: 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          side: borderSide,
          borderRadius: radius,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textLight,
      ),
    );
  }
}
