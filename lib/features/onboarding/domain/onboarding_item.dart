import 'package:flutter/material.dart';

/// Uma etapa do onboarding. Modelo de domínio — sem dependência de telas.
class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  static const List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Organize seu dia',
      description:
          'Eventos e tarefas no mesmo lugar. Uma visão da sua rotina inteira, '
          'sem dividir a cabeça entre apps.',
      icon: Icons.calendar_month_outlined,
    ),
    OnboardingItem(
      title: 'Não esqueça nada',
      description:
          'O que vence hoje aparece primeiro. O que pode esperar, espera — '
          'sem culpa e sem ruído.',
      icon: Icons.notifications_outlined,
    ),
    OnboardingItem(
      title: 'Leve em frente',
      description:
          'Marque o que fez, reagende o que não deu. Sua cadência evolui '
          'junto com você.',
      icon: Icons.check_circle_outline,
    ),
  ];
}
