import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/load_status.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../domain/task.dart';
import '../../domain/task_query.dart';
import '../../domain/task_query_engine.dart';
import '../task_query_controller.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_filter_chips.dart';
import '../widgets/task_results_bar.dart';
import '../widgets/task_search_field.dart';
import '../widgets/task_tile.dart';
import 'task_details_page.dart';

/// Aba "Tarefas": busca, filtros combináveis e a lista.
///
/// A tela não guarda a lista filtrada. Ela lê o catálogo da agenda, a consulta
/// do [TaskQueryController] e os favoritos, e **calcula** o resultado no build
/// com [applyTaskQuery]. Favoritar em outra aba ou editar uma tarefa atualiza a
/// lista sem ninguém precisar lembrar de recalcular.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  Future<void> _addTask(BuildContext context) async {
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

  Future<void> _editTask(BuildContext context, Task task) async {
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

  Future<void> _deleteTask(BuildContext context, Task task) async {
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

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    // `watch` assina os controladores: favoritar ou mudar um filtro em
    // qualquer lugar reconstrói esta tela.
    final favorites = context.watch<FavoritesController>();
    final queryController = context.read<TaskQueryController>();
    final query = context.watch<TaskQueryController>().query;

    final favoriteIds = favorites.favoriteIds;
    final all = schedule.tasks;
    final visible = applyTaskQuery(all, query, favoriteIds: favoriteIds);
    final favoriteCount =
        all.where((task) => favoriteIds.contains(task.id)).length;
    final horizontal = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-tarefas',
        onPressed: schedule.status.isError ? null : () => _addTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.md,
                horizontal,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TaskSearchField(
                    value: query.text,
                    onChanged: queryController.setText,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TaskFilterChips(
                    query: query,
                    favoriteCount: favoriteCount,
                    onStatus: queryController.setStatus,
                    onToggleFavorites: queryController.toggleOnlyFavorites,
                    onTogglePriority: queryController.togglePriority,
                    onToggleDue: queryController.toggleDue,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TaskResultsBar(
                    query: query,
                    count: visible.length,
                    onClear: queryController.clear,
                    onSort: queryController.setSort,
                  ),
                ],
              ),
            ),
          ),
          ..._results(
            context: context,
            schedule: schedule,
            favorites: favorites,
            visible: visible,
            query: query,
            horizontal: horizontal,
          ),
        ],
      ),
    );
  }

  /// Decide qual dos quatro estados ocupa o resto da tela.
  ///
  /// Um `switch` sobre o enum obriga a tratar todos os casos: esquecer um
  /// deles deixa a tela em branco sem ninguém perceber.
  List<Widget> _results({
    required BuildContext context,
    required ScheduleController schedule,
    required FavoritesController favorites,
    required List<Task> visible,
    required TaskQuery query,
    required double horizontal,
  }) {
    final status = schedule.statusFor(visible);

    switch (status) {
      case LoadStatus.loading:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingView(message: 'Carregando sua cadência...'),
          ),
        ];
      case LoadStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(
              message: 'Não foi possível carregar suas tarefas.',
              onRetry: schedule.init,
            ),
          ),
        ];
      case LoadStatus.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: _emptyIcon(query),
              message: _emptyMessage(query),
              action: _emptyAction(context, query),
            ),
          ),
        ];
      case LoadStatus.success:
        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.xs,
              horizontal,
              AppSpacing.xxl + AppSpacing.lg,
            ),
            sliver: SliverList.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final task = visible[index];
                return TaskTile(
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
                      if (value == 'edit') _editTask(context, task);
                      if (value == 'delete') _deleteTask(context, task);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                );
              },
            ),
          ),
        ];
    }
  }

  IconData _emptyIcon(TaskQuery query) {
    if (query.text.trim().isNotEmpty) return Icons.search_off;
    if (query.onlyFavorites) return Icons.star_border;
    return Icons.checklist_outlined;
  }

  String _emptyMessage(TaskQuery query) {
    if (query.hasFilters) {
      // Favoritas sozinhas têm um convite próprio: explicar como marcar é mais
      // útil do que dizer que o filtro não achou nada.
      if (_onlyFavoritesFilter(query)) {
        return 'Nenhuma tarefa favorita ainda. '
            'Toque na estrela de uma tarefa para destacá-la.';
      }
      return query.text.trim().isNotEmpty
          ? 'Nenhuma tarefa combina com essa busca.'
          : 'Nenhuma tarefa combina com esses filtros.';
    }
    return switch (query.status) {
      TaskStatusFilter.pending => 'Nenhuma tarefa pendente. Bom sinal.',
      TaskStatusFilter.done => 'Nada concluído ainda. Comece pela menor tarefa.',
      TaskStatusFilter.all => 'Nenhuma tarefa criada ainda.',
    };
  }

  bool _onlyFavoritesFilter(TaskQuery query) =>
      query.onlyFavorites &&
      query.text.trim().isEmpty &&
      query.priorities.isEmpty &&
      query.due == TaskDueFilter.any;

  Widget? _emptyAction(BuildContext context, TaskQuery query) {
    if (query.hasFilters) {
      final controller = context.read<TaskQueryController>();
      return TextButton.icon(
        onPressed: controller.clear,
        icon: const Icon(Icons.filter_alt_off),
        label: const Text('Limpar filtros'),
      );
    }
    if (query.status == TaskStatusFilter.pending) {
      return TextButton.icon(
        onPressed: () => _addTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Criar tarefa'),
      );
    }
    return null;
  }
}
