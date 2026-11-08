import 'package:flutter/material.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../domain/calendar_event.dart';

/// Linha de evento, com opção de Hero para a tela de detalhe.
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    this.onTap,
    this.heroTag,
    this.trailing,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;
  final Object? heroTag;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = timeLabel(event.start, allDay: event.allDay);

    final icon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Icon(
        event.allDay ? Icons.all_inclusive : Icons.schedule,
        size: 20,
        color: scheme.onPrimaryContainer,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        excludeSemantics: true,
        label: '${event.title}. '
            '${event.allDay ? 'Dia inteiro' : 'Às $time'}'
            '${event.allDay ? '' : ', no dia ${event.start.day}/${event.start.month}'}.',
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.only(left: 12, right: 8),
          leading: heroTag == null
              ? icon
              : Hero(tag: heroTag!, child: icon),
          title: Text(event.title),
          subtitle: Text(
            [
              if (mesmoDia(event.start, DateTime.now())) 'Hoje' else
                '${event.start.day.toString().padLeft(2, '0')}/'
                    '${event.start.month.toString().padLeft(2, '0')}',
              time,
            ].join(' • '),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}
