import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/fade_route.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/task.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_priority_view.dart';

/// Detalhe de uma tarefa: a versão completa do que aparece na lista.
///
/// É o segundo ponto de interação do favorito: a estrela daqui e a da listagem
/// leem o mesmo [FavoritesController], então marcar em um reflete no outro na
/// hora (é isso que os testes A e B da Etapa 1 verificam).
class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key, required this.task});

  static Route<void> route(Task task) => fadeRoute(TaskDetailsPage(task: task));

  /// Tarefa de origem. A versão atual é buscada na agenda a cada build, para o
  /// detalhe não ficar congelado depois de editar ou concluir.
  final Task task;

  Task _current(ScheduleController schedule) {
    for (final item in schedule.tasks) {
      if (item.id == task.id) return item;
    }
    return task;
  }

  Future<void> _edit(BuildContext context, Task current) async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => TaskDialog(
        initial: TaskDraft(
          title: current.title,
          notes: current.notes,
          dueDate: current.dueDate,
          priority: current.priority,
        ),
      ),
    );
    if (draft == null) return;
    schedule.updateTask(
      current,
      title: draft.title,
      notes: draft.notes,
      dueDate: draft.dueDate,
      priority: draft.priority,
    );
  }

  Future<void> _delete(BuildContext context, Task current) async {
    final schedule = ScheduleScope.read(context);
    final favorites = context.read<FavoritesController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('"${current.title}" será removida da sua lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // A tarefa sai da agenda e o id sai da relação de favoritos: sem isso a
    // seção "Favoritas" contaria um item que não existe mais.
    favorites.remove(current.id);
    schedule.removeTask(current);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    final favorites = context.watch<FavoritesController>();
    final current = _current(schedule);
    final isFavorite = favorites.isFavorite(current.id);
    final text = Theme.of(context).textTheme;

    final due = current.dueDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefa'),
        actions: [
          FavoriteButton(
            taskTitle: current.title,
            isFavorite: isFavorite,
            onPressed: () => favorites.toggle(current.id),
          ),
          IconButton(
            tooltip: 'Editar tarefa',
            onPressed: () => _edit(context, current),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir tarefa',
            onPressed: () => _delete(context, current),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            current.title,
            style: text.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
              decoration:
                  current.done ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Checkbox(
                value: current.done,
                semanticLabel: current.done
                    ? 'Desmarcar ${current.title}'
                    : 'Concluir ${current.title}',
                onChanged: (value) =>
                    schedule.toggleTask(current, value ?? false),
              ),
              Text(
                current.done ? 'Concluída' : 'Pendente',
                style: text.bodyMedium?.copyWith(
                  color: current.done
                      ? AppColors.textMuted
                      : AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Badge(
                icon: current.priority.icon,
                label: 'Prioridade ${current.priority.label}',
                color: current.priority.color,
                background: current.priority.background,
              ),
              if (due != null)
                _Badge(
                  icon: Icons.event_outlined,
                  label: mesmoDia(due, DateTime.now())
                      ? 'Hoje'
                      : DateFormat("EEE, d 'de' MMM", 'pt_BR').format(due),
                  color: AppColors.textMain,
                  background: AppColors.bgInput,
                ),
            ],
          ),
          if (current.notes != null && current.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'OBSERVAÇÕES',
              style: text.labelSmall?.copyWith(
                fontFamily: 'Fira Code',
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Text(current.notes!),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _edit(context, current),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(context, current),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Etiqueta compacta de prioridade/prazo, no estilo do resto do app.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
