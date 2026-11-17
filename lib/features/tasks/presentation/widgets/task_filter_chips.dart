import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/task_priority.dart';
import '../../domain/task_query.dart';
import 'task_priority_view.dart';

/// Os filtros da lista de tarefas, em `Wrap`.
///
/// Nada de rolagem horizontal: com fonte grande, chip em linha rolável esconde
/// opções e a pessoa não descobre que elas existem. Aqui as linhas quebram e
/// tudo fica visível e tocável.
class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({
    super.key,
    required this.query,
    required this.favoriteCount,
    required this.onStatus,
    required this.onToggleFavorites,
    required this.onTogglePriority,
    required this.onToggleDue,
  });

  final TaskQuery query;

  /// Quantas tarefas estão favoritadas agora (a contagem vai no rótulo).
  final int favoriteCount;

  final ValueChanged<TaskStatusFilter> onStatus;
  final VoidCallback onToggleFavorites;
  final ValueChanged<TaskPriority> onTogglePriority;
  final ValueChanged<TaskDueFilter> onToggleDue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final status in TaskStatusFilter.values)
              ChoiceChip(
                label: Text(status.label),
                selected: query.status == status,
                onSelected: (_) => onStatus(status),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            FilterChip(
              label: Text('Favoritas ($favoriteCount)'),
              selected: query.onlyFavorites,
              onSelected: (_) => onToggleFavorites(),
            ),
            for (final priority in TaskPriority.values)
              FilterChip(
                avatar: Icon(
                  priority.icon,
                  size: 16,
                  color: priority.color,
                ),
                label: Text(priority.label),
                selected: query.priorities.contains(priority),
                onSelected: (_) => onTogglePriority(priority),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final due in TaskDueFilter.values)
              if (due != TaskDueFilter.any)
                FilterChip(
                  label: Text(due.label),
                  selected: query.due == due,
                  // Tocar de novo no prazo marcado volta a "qualquer prazo".
                  onSelected: (_) => onToggleDue(due),
                ),
          ],
        ),
      ],
    );
  }
}
