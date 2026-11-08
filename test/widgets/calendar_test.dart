import 'package:cadencia/app/theme/app_theme.dart';
import 'package:cadencia/core/load_status.dart';
import 'package:cadencia/features/calendar/presentation/calendar_page.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:cadencia/features/events/presentation/pages/event_details_page.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<(ScheduleController, ProfileController)> controllers({
    List<CalendarEvent> events = const [],
  }) async {
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(latency: Duration.zero),
      eventRepository: FakeEventRepository(
        seed: events,
        latency: Duration.zero,
      ),
    );
    final profile = ProfileController(
      FakeProfileRepository(latency: Duration.zero),
    );
    await schedule.init();
    await profile.load();
    return (schedule, profile);
  }

  testWidgets('mostra o mês e os eventos do dia selecionado', (tester) async {
    final today = DateTime.now();
    final (schedule, profile) = await controllers(
      events: [
        CalendarEvent(
          title: 'Reunião de planejamento',
          start: DateTime(today.year, today.month, today.day, 9),
        ),
      ],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Reunião de planejamento'), findsOneWidget);
    expect(
      find.text('Compromissos de Hoje'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reunião de planejamento'));
    await tester.pumpAndSettle();

    expect(find.text('Evento'), findsOneWidget);
    expect(find.text('Reunião de planejamento'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('detalhe edita e exclui o evento', (tester) async {
    final event = CalendarEvent(
      title: 'Consulta',
      start: DateTime(2026, 11, 10, 14),
      end: DateTime(2026, 11, 10, 15),
      notes: 'Levar exames',
    );
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(
        seed: const [],
        latency: Duration.zero,
      ),
      eventRepository: FakeEventRepository(
        seed: [event],
        latency: Duration.zero,
      ),
    );
    final profile = ProfileController(
      FakeProfileRepository(latency: Duration.zero),
    );
    await schedule.init();
    await profile.load();

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: EventDetailsPage(event: event),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Consulta'), findsOneWidget);
    expect(find.text('Levar exames'), findsOneWidget);
    expect(
      find.textContaining(DateFormat('HH:mm').format(event.start)),
      findsWidgets,
    );

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Consulta médica');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(schedule.events.single.title, 'Consulta médica');
    expect(find.text('Consulta médica'), findsOneWidget);

    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(find.text('Excluir evento?'), findsOneWidget);
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    expect(schedule.events, isEmpty);
    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('erro no calendário oferece tentar novamente', (tester) async {
    useTallScreen(tester);
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(
        latency: Duration.zero,
        failuresRemaining: 1,
      ),
      eventRepository: FakeEventRepository(latency: Duration.zero),    );
    final profile = ProfileController(
      FakeProfileRepository(latency: Duration.zero),
    );
    await schedule.init();
    await profile.load();
    expect(schedule.status, LoadStatus.error);

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const CalendarPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsWidgets);

    await tester.tap(find.text('Tentar novamente').first);
    await tester.pumpAndSettle();
    expect(schedule.status, LoadStatus.success);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  test('tema é escuro e usa a paleta do Cadência', () {
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
