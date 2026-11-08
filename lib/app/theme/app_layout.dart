import 'dart:math' as math;

import 'app_spacing.dart';

/// Largura máxima de leitura e recuo lateral responsivo.
///
/// Em telas largas (web/tablet) o conteúdo não estica até a borda: fica
/// centralizado, com no máximo [maxContentWidth] pixels.
abstract final class AppLayout {
  static const double maxContentWidth = 640;

  static double horizontalPadding(double screenWidth) {
    return math.max(
      AppSpacing.md,
      (screenWidth - maxContentWidth) / 2,
    );
  }
}
