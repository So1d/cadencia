import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Cabeçalho de seção reutilizável (título + ação opcional).
///
/// Um componente só para um padrão repetido em várias telas mantém o ritmo
/// visual igual no app inteiro.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
