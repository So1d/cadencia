import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/load_status.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/task.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_tile.dart';
import 'task_details_page.dart';

enum TaskFilter { pending, done, favorite, all }

/// Aba "Tarefas": lista completa com filtros e ações.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  TaskFilter _filter = TaskFilter.pending;

  /// As favoritas na ordem em que foram marcadas: a relação guarda ids, e a
  /// tarefa em si vive na agenda. Id de tarefa excluída simplesmente não rende
  /// linha (e `favorites.remove` já tira na exclusão).
  List<Task> _favoriteTasks(
    ScheduleController schedule,
    FavoritesController favorites,
  ) {
    final byId = {for (final task in schedule.tasks) task.id: task};
    return [
      for (final id in favorites.favoriteIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  List<Task> _filtered(
    ScheduleController schedule,
    FavoritesController favorites,
  ) {
    final all = schedule.tasksSorted;
    return switch (_filter) {
      TaskFilter.pending => all.where((task) => !task.done).toList(),
      TaskFilter.done => all.where((task) => task.done).toList(),
      TaskFilter.favorite => _favoriteTasks(schedule, favorites),
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
    final favorites = context.read<FavoritesController>();
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
    if (confirmed == true) {
      favorites.remove(task.id);
      schedule.removeTask(task);
    }
  }

  String get _emptyMessage => switch (_filter) {
        TaskFilter.pending => 'Nenhuma tarefa pendente. Bom sinal.',
        TaskFilter.done => 'Nada concluído ainda. Comece pela menor tarefa.',
        TaskFilter.favorite =>
          'Nenhuma tarefa favorita ainda. Toque na estrela de uma tarefa para destacá-la.',
        TaskFilter.all => 'Nenhuma tarefa criada ainda.',
      };

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    // `watch` assina o controlador: marcar uma estrela em qualquer lugar do app
    // reconstrói esta tela. Nada de guardar booleano próprio aqui.
    final favorites = context.watch<FavoritesController>();
    final all = schedule.tasksSorted;
    final tasks = _filtered(schedule, favorites);
    final pending = all.where((task) => !task.done).length;
    final done = all.length - pending;
    final favorite = _favoriteTasks(schedule, favorites).length;
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
              // Quatro segmentos com contagem não cabem em 360dp: o seletor
              // rola na horizontal em vez de estourar a largura.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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
                    ButtonSegment(
                      value: TaskFilter.favorite,
                      label: Text('Favoritas ($favorite)'),
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
            ),
          Expanded(
            child: StatusView(
              status: schedule.statusFor(tasks),
              isEmpty: tasks.isEmpty,
              onRetry: schedule.init,
              errorMessage: 'Não foi possível carregar suas tarefas.',
              emptyIcon: _filter == TaskFilter.favorite
                  ? Icons.star_border
                  : Icons.checklist_outlined,
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
                      isFavorite: favorites.isFavorite(task.id),
                      onTap: () => Navigator.of(context).push(
                        TaskDetailsPage.route(task),
                      ),
                      onToggle: (value) => schedule.toggleTask(task, value),
                      onToggleFavorite: () => favorites.toggle(task.id),
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
