import 'package:flutter/material.dart';

import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/load_status.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../../domain/task.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_tile.dart';

enum TaskFilter { pending, done, all }

/// Aba "Tarefas": lista completa com filtros e ações.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  TaskFilter _filter = TaskFilter.pending;

  List<Task> _filtered(ScheduleController schedule) {
    final all = schedule.tasksSorted;
    return switch (_filter) {
      TaskFilter.pending => all.where((task) => !task.done).toList(),
      TaskFilter.done => all.where((task) => task.done).toList(),
      TaskFilter.all => all,
    };
  }

  Future<void> _addTask() async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => const TaskDialog(),
    );
    if (draft == null) return;
    schedule.addTask(
      title: draft.title,
      notes: draft.notes,
      dueDate: draft.dueDate,
      priority: draft.priority,
    );
  }

  Future<void> _editTask(Task task) async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => TaskDialog(
        initial: TaskDraft(
          title: task.title,
          notes: task.notes,
          dueDate: task.dueDate,
          priority: task.priority,
        ),
      ),
    );
    if (draft == null) return;
    schedule.updateTask(
      task,
      title: draft.title,
      notes: draft.notes,
      dueDate: draft.dueDate,
      priority: draft.priority,
    );
  }

  Future<void> _deleteTask(Task task) async {
    final schedule = ScheduleScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir tarefa?'),
        content: Text('"${task.title}" será removida da sua lista.'),
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
    if (confirmed == true) schedule.removeTask(task);
  }

  String get _emptyMessage => switch (_filter) {
        TaskFilter.pending => 'Nenhuma tarefa pendente. Bom sinal.',
        TaskFilter.done => 'Nada concluído ainda. Comece pela menor tarefa.',
        TaskFilter.all => 'Nenhuma tarefa criada ainda.',
      };

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    final all = schedule.tasksSorted;
    final tasks = _filtered(schedule);
    final pending = all.where((task) => !task.done).length;
    final done = all.length - pending;
    final horizontal = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-tarefas',
        onPressed: schedule.status.isError ? null : _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: Column(
        children: [
          if (schedule.status.hasData)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.md,
                horizontal,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<TaskFilter>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: TaskFilter.pending,
                          label: Text('Pendentes ($pending)'),
                        ),
                        ButtonSegment(
                          value: TaskFilter.done,
                          label: Text('Feitas ($done)'),
                        ),
                        const ButtonSegment(
                          value: TaskFilter.all,
                          label: Text('Todas'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) =>
                          setState(() => _filter = selection.first),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StatusView(
              status: schedule.statusFor(tasks),
              isEmpty: tasks.isEmpty,
              onRetry: schedule.init,
              errorMessage: 'Não foi possível carregar suas tarefas.',
              emptyIcon: Icons.checklist_outlined,
              emptyMessage: _emptyMessage,
              emptyAction: _filter == TaskFilter.pending
                  ? TextButton.icon(
                      onPressed: _addTask,
                      icon: const Icon(Icons.add),
                      label: const Text('Criar tarefa'),
                    )
                  : null,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.xs,
                  horizontal,
                  AppSpacing.xxl + AppSpacing.lg,
                ),
                children: [
                  for (final task in tasks)
                    TaskTile(
                      task: task,
                      onTap: () => _editTask(task),
                      onToggle: (value) => schedule.toggleTask(task, value),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Opções de ${task.title}',
                        onSelected: (value) {
                          if (value == 'edit') _editTask(task);
                          if (value == 'delete') _deleteTask(task);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
