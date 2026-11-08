import 'package:flutter/widgets.dart';

/// Escala de espaçamento do Cadência.
///
/// Um número mágico repetido em várias telas vira inconsistência. Aqui os
/// valores têm nome — e mudar o ritmo do app inteiro é mexer num lugar só.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Respiro interno padrão de cartões e blocos.
  static const EdgeInsets card = EdgeInsets.all(md);
}
