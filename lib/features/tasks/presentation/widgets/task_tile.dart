import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../domain/task.dart';
import 'task_priority_view.dart';

/// Linha de tarefa com marcação, prioridade e data.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.trailing,
  });

  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Sem `excludeSemantics`: o checkbox e o menu continuam acessíveis
      // para leitores de tela, cada um com seu próprio rótulo.
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.only(left: 4, right: 8),
        leading: Checkbox(
          value: task.done,
          semanticLabel:
              '${task.done ? 'Desmarcar' : 'Concluir'} ${task.title}',
          onChanged: (value) => onToggle(value ?? false),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done ? scheme.outline : null,
          ),
        ),
        subtitle: (due == null && (task.notes == null || task.notes!.isEmpty))
            ? null
            : Text(
                [
                  if (due != null)
                    mesmoDia(due, DateTime.now())
                        ? 'Hoje'
                        : DateFormat('EEE, d MMM', 'pt_BR').format(due),
                  if (task.notes != null && task.notes!.isNotEmpty)
                    task.notes!,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Prioridade ${task.priority.label}',
              child: Icon(
                task.priority.icon,
                size: 18,
                color: task.priority.color,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
