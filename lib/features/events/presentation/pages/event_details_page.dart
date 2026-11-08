import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../state/schedule_controller.dart';
import '../../../../state/schedule_scope.dart';
import '../../domain/calendar_event.dart';
import '../widgets/event_dialog.dart';

/// Detalhe de um evento: a versão completa do que aparece na lista.
class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key, required this.event, this.heroTag});

  final CalendarEvent event;

  /// Tag do Hero da tela de origem. Sem ela, o detalhe abre sem animação.
  final Object? heroTag;

  CalendarEvent _current(ScheduleController schedule) {
    for (final item in schedule.events) {
      if (item.id == event.id) return item;
    }
    return event;
  }

  Future<void> _edit(BuildContext context, CalendarEvent current) async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<EventDraft>(
      context: context,
      builder: (_) => EventDialog(
        initial: EventDraft(
          title: current.title,
          start: current.start,
          end: current.end,
          notes: current.notes,
          allDay: current.allDay,
        ),
      ),
    );
    if (draft == null) return;
    schedule.updateEvent(
      current,
      title: draft.title,
      start: draft.start,
      end: draft.end,
      notes: draft.notes,
      allDay: draft.allDay,
    );
  }

  Future<void> _delete(BuildContext context, CalendarEvent current) async {
    final schedule = ScheduleScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: Text('"${current.title}" será removido da sua agenda.'),
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
    schedule.removeEvent(current);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    final current = _current(schedule);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final date = DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR')
        .format(current.start);
    final time = current.allDay
        ? 'Dia inteiro'
        : current.end == null
            ? 'Às ${timeLabel(current.start)}'
            : '${timeLabel(current.start)} – ${timeLabel(current.end!)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento'),
        actions: [
          IconButton(
            tooltip: 'Editar evento',
            onPressed: () => _edit(context, current),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir evento',
            onPressed: () => _delete(context, current),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroOrPlain(
                tag: heroTag,
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(
                    current.allDay ? Icons.all_inclusive : Icons.schedule,
                    size: 30,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.title,
                      style: text.headlineSmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$date • $time',
                      style: text.bodyMedium?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (current.notes != null && current.notes!.isNotEmpty) ...[
            Text(
              'OBSERVAÇÕES',
              style: text.labelSmall?.copyWith(
                fontFamily: 'monospace',
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
            const SizedBox(height: AppSpacing.lg),
          ],
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

/// Usa `Hero` só quando a tela de origem informou uma tag.
class _HeroOrPlain extends StatelessWidget {
  const _HeroOrPlain({this.tag, required this.child});

  final Object? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    if (tag == null) return child;
    return Hero(tag: tag, child: child);
  }
}
