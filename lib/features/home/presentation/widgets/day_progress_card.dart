import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// Cartão de progresso do dia.
///
/// Mostra quantas tarefas de hoje foram concluídas e qual é a meta diária
/// definida no perfil.
class DayProgressCard extends StatelessWidget {
  const DayProgressCard({
    super.key,
    required this.done,
    required this.total,
    required this.goal,
  });

  final int done;
  final int total;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // A barra representa o avanço rumo à meta diária do perfil — não apenas
    // a proporção de tarefas marcadas. Assim, mudar a meta muda o progresso.
    final value = total == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final label = total == 0
        ? 'Nenhuma tarefa marcada para hoje • meta: $goal'
        : '$done de $total tarefas concluídas • meta: $goal';

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progresso do dia', style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: total == 0
                  ? 'Nenhuma tarefa para hoje. Meta: $goal.'
                  : 'Progresso do dia: $done de $total tarefas concluídas. '
                      'Meta: $goal.',
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
