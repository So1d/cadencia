import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Tema do Cadência: brutalista dark, raio 2px, sem sombra, borda dura.
///
/// O visual é decidido **aqui**, não espalhado pelas telas. Trocar a paleta ou
/// o formato dos botões é mexer neste arquivo, e só nele.
abstract class AppTheme {
  static const BorderRadius radius =
      BorderRadius.all(Radius.circular(AppRadius.sm));
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
      tertiary: AppColors.warning,
      onTertiary: AppColors.textLight,
      error: AppColors.danger,
      onError: AppColors.textLight,
      surface: AppColors.bgSecondary,
      onSurface: AppColors.textMain,
      surfaceContainerHighest: AppColors.bgTertiary,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.border,
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
          fontSize: 18,
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
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textLight),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(side: borderSide, borderRadius: radius),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        helperStyle: TextStyle(color: AppColors.textMuted),
        counterStyle: TextStyle(color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        indicatorColor: AppColors.primaryHover.withValues(alpha: 0.55),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.textLight : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.textLight : AppColors.textMuted,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: borderSide,
          borderRadius: radius,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.bgInput,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.bgInput,
        selectedColor: AppColors.primaryHover,
        side: borderSide,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        labelStyle: const TextStyle(color: AppColors.textMain),
        secondaryLabelStyle: const TextStyle(color: AppColors.textLight),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: borderSide,
          borderRadius: radius,
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: AppColors.textMain),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: borderSide,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
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
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.textMain,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textLight,
      ),
    );
  }
}
