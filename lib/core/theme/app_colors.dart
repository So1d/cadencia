import 'package:flutter/material.dart';

/// Paleta do design system "Minimalist Brutalist Dark".
/// Espelha o CSS original: fundos acinzentados, verde como primária, bordas duras.
abstract class AppColors {
  // Fundos
  static const bgPrimary = Color(0xFF222222);
  static const bgSecondary = Color(0xFF262626);
  static const bgTertiary = Color(0xFF2A2A2A);
  static const bgHover = Color(0xFF2C302D);
  static const bgInput = Color(0xFF1E1E1E);

  // Cores de ação
  static const primary = Color(0xFF6F9C7F);
  static const primaryHover = Color(0xFF425E4C);
  static const danger = Color(0xFFB25F5D);
  static const warning = Color(0xFFCC5500);
  static const success = Color(0xFF6F9C7F);

  // Texto
  static const textMain = Color(0xFFBCC4C9);
  static const textMuted = Color(0xFF6B7276);
  static const textLight = Color(0xFFFEFEFE);

  // Bordas
  static const border = Color(0xFF0B0D0F);
  static const borderFocus = Color(0xFF6F9C7F);
  static const borderLight = Color(0xFF262626);
}
