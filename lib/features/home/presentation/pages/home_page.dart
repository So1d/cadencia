import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/fade_route.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/load_status.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../features/events/domain/calendar_event.dart';
import '../../../../features/events/presentation/pages/event_details_page.dart';
import '../../../../features/events/presentation/widgets/event_dialog.dart';
import '../../../../features/events/presentation/widgets/event_tile.dart';
import '../../../../features/favorites/presentation/favorites_controller.dart';
import '../../../../features/profile/domain/entities/profile_focus.dart';
import '../../../../features/profile/presentation/pages/profile_form_page.dart';
import '../../../../features/profile/presentation/profile_scope.dart';
import '../../../../features/tasks/domain/task.dart';
import '../../../../features/tasks/domain/task_priority.dart';
import '../../../../features/tasks/domain/task_query.dart';
import '../../../../features/tasks/presentation/pages/task_details_page.dart';
import '../../../../features/tasks/presentation/task_query_controller.dart';
import '../../../../features/tasks/presentation/widgets/task_dialog.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../widgets/day_progress_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/profile_prompt_card.dart';

/// Aba "Hoje": saudação, progresso e o que importa nas próximas horas.
///
/// A Home não abre a aba Tarefas por conta própria: quem sabe qual aba está
/// aberta é a casca. Ela pede a navegação por [onOpenTasks] e entrega os dados
/// da intenção pelo `TaskQueryController`. Dois canais, um para dados e outro
/// para navegação.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpenTasks});

  /// Callback da casca: levar a pessoa à aba Tarefas.
  final VoidCallback? onOpenTasks;

  void _openTasks() => onOpenTasks?.call();

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    final favorites = context.watch<FavoritesController>();
    final profile = ProfileScope.of(context).profile;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final events = schedule.eventsOfDay(today);
    final tasks = schedule.tasksOfDay(today);
    final done = tasks.where((task) => task.done).length;

    // O perfil decide a ordem: quem escolheu "Agenda" vê os compromissos
    // primeiro; "Prazos" e "Equilíbrio" mantêm as tarefas no topo.
    final eventsFirst = profile.primaryFocus == ProfileFocus.events;

    final agendaSection = _AgendaSection(
      schedule: schedule,
      events: events,
      onAdd: () => _addEvent(context, today),
    );

    final tasksSection = _TasksSection(
      schedule: schedule,
      favorites: favorites,
      tasks: tasks,
      onAdd: () => _addTask(context),
      onOpen: (task) => Navigator.of(context).push(
        TaskDetailsPage.route(task),
      ),
      onShowAll: () {
        // "Ver todas" começa do zero: limpa os filtros e abre a aba inteira.
        context.read<TaskQueryController>().clear();
        _openTasks();
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CADÊNCIA',
          style: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 14,
            letterSpacing: 4,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-hoje',
        onPressed: schedule.status.isError ? null : () => _quickAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppLayout.horizontalPadding(MediaQuery.sizeOf(context).width),
          AppSpacing.md,
          AppLayout.horizontalPadding(MediaQuery.sizeOf(context).width),
          AppSpacing.xxl + AppSpacing.lg,
        ),
        children: [
          GreetingHeader(name: profile.name, now: now),
          const SizedBox(height: AppSpacing.md),
          _HomeSearchAndShortcuts(
            onSearch: _openTasks,
            onHighPriority: () {
              // Atalho, não toggle: começa do zero e mostra só a prioridade
              // alta, sem herdar busca ou prazo de antes.
              context
                  .read<TaskQueryController>()
                  .showOnly(priority: TaskPriority.high);
              _openTasks();
            },
            onDueToday: () {
              context
                  .read<TaskQueryController>()
                  .showOnly(due: TaskDueFilter.today);
              _openTasks();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (!profile.isComplete) ...[
            ProfilePromptCard(
              onComplete: () => Navigator.of(context).push(
                ProfileFormPage.route(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          DayProgressCard(
            done: done,
            total: tasks.length,
            goal: profile.dailyGoal,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (eventsFirst) ...[
            agendaSection,
            const SizedBox(height: AppSpacing.lg),
            tasksSection,
          ] else ...[
            tasksSection,
            const SizedBox(height: AppSpacing.lg),
            agendaSection,
          ],
        ],
      ),
    );
  }

  void _quickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Novo evento'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addEvent(context, DateTime.now());
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Nova tarefa'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addTask(context);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  Future<void> _addEvent(BuildContext context, DateTime day) async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<EventDraft>(
      context: context,
      builder: (_) => EventDialog(initialDay: day),
    );
    if (draft == null) return;
    schedule.addEvent(
      title: draft.title,
      start: draft.start,
      end: draft.end,
      notes: draft.notes,
      allDay: draft.allDay,
    );
  }

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
}

class _AgendaSection extends StatelessWidget {
  const _AgendaSection({
    required this.schedule,
    required this.events,
    required this.onAdd,
  });

  final ScheduleController schedule;
  final List<CalendarEvent> events;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Agenda de hoje',
          action: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo'),
          ),
        ),
        StatusView(
          status: schedule.statusFor(events),
          isEmpty: events.isEmpty,
          onRetry: schedule.init,
          errorMessage: 'Não foi possível carregar seus eventos.',
          emptyIcon: Icons.event_available_outlined,
          emptyMessage: 'Nenhum compromisso hoje. O dia é seu.',
          emptyAction: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Criar evento'),
          ),
          child: Column(
            children: [
              for (final event in events)
                EventTile(
                  event: event,
                  // Prefixo por tela: Home e Agenda vivem na mesma rota
                  // (IndexedStack) e não podem repetir a mesma tag.
                  heroTag: 'home-event-${event.id}',
                  onTap: () => Navigator.of(context).push(
                    fadeRoute(
                      EventDetailsPage(
                        event: event,
                        heroTag: 'home-event-${event.id}',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({
    required this.schedule,
    required this.favorites,
    required this.tasks,
    required this.onAdd,
    required this.onOpen,
    required this.onShowAll,
  });

  final ScheduleController schedule;
  final FavoritesController favorites;
  final List<Task> tasks;
  final VoidCallback onAdd;
  final ValueChanged<Task> onOpen;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Tarefas de hoje',
          action: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nova'),
          ),
        ),
        StatusView(
          status: schedule.statusFor(tasks),
          isEmpty: tasks.isEmpty,
          onRetry: schedule.init,
          errorMessage: 'Não foi possível carregar suas tarefas.',
          emptyIcon: Icons.wb_sunny_outlined,
          emptyMessage: 'Nenhuma tarefa marcada para hoje.',
          emptyAction: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Criar tarefa'),
          ),
          child: Column(
            children: [
              for (final task in tasks)
                TaskTile(
                  task: task,
                  isFavorite: favorites.isFavorite(task.id),
                  onTap: () => onOpen(task),
                  onToggle: (value) => schedule.toggleTask(task, value),
                  onToggleFavorite: () => favorites.toggle(task.id),
                ),
              if (tasks.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onShowAll,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Ver todas as tarefas'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Campo-botão de busca e os atalhos que abrem a aba Tarefas já recortada.
///
/// O campo aqui não digita: a aba Tarefas é que tem o campo de verdade, com
/// atraso para não filtrar a cada letra. Este atalho só leva até lá.
class _HomeSearchAndShortcuts extends StatelessWidget {
  const _HomeSearchAndShortcuts({
    required this.onSearch,
    required this.onHighPriority,
    required this.onDueToday,
  });

  final VoidCallback onSearch;
  final VoidCallback onHighPriority;
  final VoidCallback onDueToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Buscar tarefas',
          child: InkWell(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Buscar tarefas...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            ActionChip(
              avatar: const Icon(
                Icons.flag,
                size: 16,
                color: AppColors.danger,
              ),
              label: const Text('Alta prioridade'),
              onPressed: onHighPriority,
            ),
            ActionChip(
              avatar: const Icon(
                Icons.event_available_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text('Vence hoje'),
              onPressed: onDueToday,
            ),
          ],
        ),
      ],
    );
  }
}
