import 'package:cadencia/core/load_status.dart';
import 'package:cadencia/core/utils/date_helpers.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:cadencia/features/home/presentation/pages/home_page.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/domain/entities/profile_focus.dart';
import 'package:cadencia/features/profile/domain/entities/user_profile.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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
    List<Task> tasks = const [],
    List<CalendarEvent> events = const [],
    UserProfile profile = UserProfile.empty,
    int failuresRemaining = 0,
  }) async {
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(
        seed: tasks,
        latency: Duration.zero,
        failuresRemaining: failuresRemaining,
      ),
      eventRepository: FakeEventRepository(
        seed: events,
        latency: Duration.zero,
      ),
    );
    final profileController = ProfileController(
      FakeProfileRepository(initial: profile, latency: Duration.zero),
    );
    await schedule.init();
    await profileController.load();
    return (schedule, profileController);
  }

  testWidgets('sem perfil mostra saudação simples e convite', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers();

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${greetingFor(DateTime.now())}!'), findsOneWidget);
    expect(find.text('Completar perfil'), findsOneWidget);
    expect(find.text('Tarefas de hoje'), findsOneWidget);
    expect(find.text('Agenda de hoje'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('com perfil mostra o nome e esconde o convite', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      profile: const UserProfile(
        name: 'Ana',
        focus: {ProfileFocus.deadlines},
      ),
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('${greetingFor(DateTime.now())}, Ana!'),
      findsOneWidget,
    );
    expect(find.text('Completar perfil'), findsNothing);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('mostra tarefas e eventos de hoje', (tester) async {
    useTallScreen(tester);
    final today = DateTime.now();
    final (schedule, profile) = await controllers(
      tasks: [
        Task(
          title: 'Enviar relatório',
          dueDate: DateTime(today.year, today.month, today.day),
        ),
      ],
      events: [
        CalendarEvent(
          title: 'Reunião',
          start: DateTime(today.year, today.month, today.day, 9),
        ),
      ],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enviar relatório'), findsOneWidget);
    expect(find.text('Reunião'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('a barra de progresso usa a meta diária do perfil',
      (tester) async {
    useTallScreen(tester);
    final today = DateTime.now();
    final (schedule, profile) = await controllers(
      tasks: [
        Task(
          title: 'Feita',
          dueDate: DateTime(today.year, today.month, today.day),
          done: true,
        ),
      ],
      profile: const UserProfile(
        focus: {ProfileFocus.deadlines},
        dailyGoal: 5,
      ),
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.2, 0.001));
    expect(find.text('1 de 1 tarefas concluídas • meta: 5'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('tarefa criada na Home respeita a opção "Sem data"',
      (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers();

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ideia solta');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(schedule.tasks.single.title, 'Ideia solta');
    expect(schedule.tasks.single.dueDate, isNull);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('perfil com foco em agenda inverte a ordem das seções',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (schedule, profile) = await controllers(
      profile: const UserProfile(focus: {ProfileFocus.events}),
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final agendaY = tester.getTopLeft(find.text('Agenda de hoje')).dy;
    final tasksY = tester.getTopLeft(find.text('Tarefas de hoje')).dy;
    expect(agendaY, lessThan(tasksY));

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('perfil com foco em prazos coloca tarefas primeiro',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (schedule, profile) = await controllers(
      profile: const UserProfile(focus: {ProfileFocus.deadlines}),
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    final tasksY = tester.getTopLeft(find.text('Tarefas de hoje')).dy;
    final agendaY = tester.getTopLeft(find.text('Agenda de hoje')).dy;
    expect(tasksY, lessThan(agendaY));

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('erro mostra retry e recupera', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(failuresRemaining: 1);
    expect(schedule.status, LoadStatus.error);

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsWidgets);

    await tester.tap(find.text('Tentar novamente').first);
    await tester.pumpAndSettle();

    expect(schedule.status, LoadStatus.success);
    expect(find.text('Nenhum compromisso hoje. O dia é seu.'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });
}
