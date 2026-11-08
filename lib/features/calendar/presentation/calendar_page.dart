import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;

import '../../../../app/routes/fade_route.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/load_status.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../features/events/domain/calendar_event.dart';
import '../../../../features/events/presentation/pages/event_details_page.dart';
import '../../../../features/events/presentation/widgets/event_dialog.dart';
import '../../../../features/events/presentation/widgets/event_tile.dart';
import '../../../../features/profile/presentation/profile_scope.dart';
import '../../../../state/schedule_scope.dart';

/// Aba "Agenda": visão mensal com marcadores e eventos do dia selecionado.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  DateTime _selectedDay = dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _focusedDay = _selectedDay;
  }

  Future<void> _addEvent() async {
    final schedule = ScheduleScope.read(context);
    final draft = await showDialog<EventDraft>(
      context: context,
      builder: (_) => EventDialog(initialDay: _selectedDay),
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

  @override
  Widget build(BuildContext context) {
    final schedule = ScheduleScope.of(context);
    final profile = ProfileScope.of(context).profile;
    final events = schedule.eventsOfDay(_selectedDay);
    final horizontal = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    final isToday = mesmoDia(_selectedDay, DateTime.now());
    final dayLabel = isToday
        ? 'Hoje'
        : '${_selectedDay.day.toString().padLeft(2, '0')}/'
            '${_selectedDay.month.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-agenda',
        onPressed: schedule.status.isError ? null : _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.md,
          horizontal,
          AppSpacing.xxl + AppSpacing.lg,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: TableCalendar<CalendarEvent>(
                locale: 'pt_BR',
                firstDay: DateTime.utc(2000),
                lastDay: DateTime.utc(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => mesmoDia(day, _selectedDay),
                startingDayOfWeek: profile.weekStartsMonday
                    ? StartingDayOfWeek.monday
                    : StartingDayOfWeek.sunday,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mês',
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  leftChevronIcon:
                      Icon(Icons.chevron_left, color: AppColors.textMain),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: AppColors.textMain),
                  titleTextStyle: TextStyle(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppColors.textMuted),
                  weekendStyle: TextStyle(color: AppColors.textMuted),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle:
                      const TextStyle(color: AppColors.textMain),
                  weekendTextStyle:
                      const TextStyle(color: AppColors.textMuted),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
                eventLoader: schedule.eventsOfDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = dateOnly(selectedDay);
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Compromissos de $dayLabel',
            action: TextButton.icon(
              onPressed: _addEvent,
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
            emptyMessage: 'Nenhum compromisso neste dia.',
            emptyAction: TextButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Criar evento'),
            ),
            child: Column(
              children: [
                for (final event in events)
                  EventTile(
                    event: event,
                    heroTag: 'calendar-event-${event.id}',
                    onTap: () => Navigator.of(context).push(
                      fadeRoute(
                        EventDetailsPage(
                          event: event,
                          heroTag: 'calendar-event-${event.id}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
