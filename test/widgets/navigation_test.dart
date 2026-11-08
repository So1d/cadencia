import 'package:cadencia/app/app_dependencies.dart';
import 'package:cadencia/app/cadencia_app.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:cadencia/features/home/presentation/pages/home_page.dart';
import 'package:cadencia/features/onboarding/data/onboarding_storage.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AppDependencies dependencies({
  List<Task> tasks = const [],
  List<CalendarEvent> events = const [],
}) {
  final preferences = SharedPreferencesAsync();
  return AppDependencies(
    taskRepository: FakeTaskRepository(
      seed: tasks,
      latency: Duration.zero,
    ),
    eventRepository: FakeEventRepository(
      seed: events,
      latency: Duration.zero,
    ),
    profileRepository: FakeProfileRepository(latency: Duration.zero),
    onboardingStorage: OnboardingStorage(preferences: preferences),
  );
}

Future<void> startApp(WidgetTester tester) async {
  await tester.pumpWidget(CadenciaApp(dependencies: dependencies()));
  await tester.pump(const Duration(milliseconds: 950));
  await tester.pumpAndSettle();
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
  });

  testWidgets('primeira execução: splash leva ao onboarding', (tester) async {
    await tester.pumpWidget(CadenciaApp(dependencies: dependencies()));
    expect(find.text('CADÊNCIA'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Organize seu dia'), findsOneWidget);
    expect(find.text('Pular'), findsOneWidget);
  });

  testWidgets('pular onboarding leva à shell e grava a conclusão',
      (tester) async {
    await startApp(tester);
    expect(find.text('Organize seu dia'), findsOneWidget);

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    final storage = OnboardingStorage(preferences: SharedPreferencesAsync());
    expect(await storage.isCompleted(), isTrue);
  });

  testWidgets('segunda execução: splash leva direto à shell', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});

    await startApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Organize seu dia'), findsNothing);
    expect(find.text('CADÊNCIA'), findsOneWidget);
  });

  testWidgets('evento da Home abre o detalhe sem conflito de Hero',
      (tester) async {
    useTallScreen(tester);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});

    final now = DateTime.now();
    await tester.pumpWidget(
      CadenciaApp(
        dependencies: dependencies(
          events: [
            CalendarEvent(
              title: 'Reunião',
              start: DateTime(now.year, now.month, now.day, 9),
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    final event = find.descendant(
      of: find.byType(HomePage),
      matching: find.text('Reunião'),
    );
    expect(event, findsOneWidget);

    await tester.tap(event);
    await tester.pumpAndSettle();

    expect(find.text('Evento'), findsOneWidget);
    expect(find.text('Reunião'), findsOneWidget);
  });

  testWidgets('as quatro abas trocam o índice da NavigationBar',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});
    await startApp(tester);

    Future<int> currentIndex() async =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    expect(await currentIndex(), 0);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(await currentIndex(), 1);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.checklist_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(await currentIndex(), 2);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.person_outline),
      ),
    );
    await tester.pumpAndSettle();
    expect(await currentIndex(), 3);
  });
}
