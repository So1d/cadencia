import 'package:cadencia/app/app_dependencies.dart';
import 'package:cadencia/app/cadencia_app.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/favorites/data/fake_favorites_repository.dart';
import 'package:cadencia/features/home/presentation/pages/home_page.dart';
import 'package:cadencia/features/onboarding/data/onboarding_storage.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/presentation/pages/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Integração Home ↔ Tarefas pela casca de verdade: a Home pede a navegação
/// por callback e entrega o recorte pelo controlador de consulta.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});
  });

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);

  List<Task> tasks() => [
        Task(
          id: 'alta',
          title: 'Revisar contrato',
          priority: TaskPriority.high,
          dueDate: hoje,
        ),
        Task(
          id: 'media',
          title: 'Responder e-mails',
          priority: TaskPriority.medium,
          dueDate: hoje,
        ),
        Task(
          id: 'baixa',
          title: 'Arquivar notas',
          priority: TaskPriority.low,
        ),
      ];

  Future<void> startApp(WidgetTester tester) async {
    final dependencies = AppDependencies(
      taskRepository: FakeTaskRepository(
        seed: tasks(),
        latency: Duration.zero,
      ),
      eventRepository: FakeEventRepository(latency: Duration.zero),
      profileRepository: FakeProfileRepository(latency: Duration.zero),
      favoritesRepository: FakeFavoritesRepository(latency: Duration.zero),
      onboardingStorage: OnboardingStorage(),
    );

    await tester.pumpWidget(CadenciaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  Finder inTasks(Finder matching) => find.descendant(
        of: find.byType(TasksPage),
        matching: matching,
      );

  Finder inHome(Finder matching) => find.descendant(
        of: find.byType(HomePage),
        matching: matching,
      );

  Finder navIcon(IconData icon) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(icon),
      );

  int selectedTab(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  testWidgets('atalho de prioridade da Home abre Tarefas já recortada',
      (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    await tester.tap(inHome(find.text('Alta prioridade')));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 2);
    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Alta')).selected,
      isTrue,
    );
    expect(inTasks(find.text('Revisar contrato')), findsOneWidget);
    expect(inTasks(find.text('Responder e-mails')), findsNothing);
    expect(inTasks(find.text('Arquivar notas')), findsNothing);
  });

  testWidgets('atalho "Vence hoje" liga o recorte de prazo', (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    await tester.tap(inHome(find.text('Vence hoje')));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 2);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Vence hoje'))
          .selected,
      isTrue,
    );
    expect(inTasks(find.text('Arquivar notas')), findsNothing);
    expect(inTasks(find.text('Revisar contrato')), findsOneWidget);
  });

  testWidgets('"Ver todas as tarefas" limpa os filtros antes de abrir',
      (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    // Deixa um recorte ligado para provar que "Ver todas" começa do zero.
    await tester.tap(inHome(find.text('Alta prioridade')));
    await tester.pumpAndSettle();

    // Volta para a Home: é lá que fica o "Ver todas".
    await tester.tap(navIcon(Icons.wb_sunny_outlined));
    await tester.pumpAndSettle();

    await tester.ensureVisible(inHome(find.text('Ver todas as tarefas')));
    await tester.pumpAndSettle();
    await tester.tap(inHome(find.text('Ver todas as tarefas')));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 2);
    expect(
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Alta')).selected,
      isFalse,
    );
    expect(inTasks(find.text('Arquivar notas')), findsOneWidget);
    expect(inTasks(find.text('3 tarefas encontradas')), findsOneWidget);
  });

  testWidgets('busca da Home abre a aba sem mexer nos filtros', (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    await tester.tap(inHome(find.text('Buscar tarefas...')));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 2);
    expect(inTasks(find.byType(TextField)), findsOneWidget);
  });

  testWidgets('filtros sobrevivem à troca de aba', (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    await tester.tap(inHome(find.text('Alta prioridade')));
    await tester.pumpAndSettle();

    await tester.enterText(inTasks(find.byType(TextField)), 'contrato');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(navIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);

    await tester.tap(navIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 2);
    expect(
      tester
          .widget<TextField>(inTasks(find.byType(TextField)))
          .controller!
          .text,
      'contrato',
    );
    expect(inTasks(find.text('1 tarefa encontrada')), findsOneWidget);
  });

  testWidgets('favoritar na Home aparece no filtro de favoritas', (tester) async {
    useTallScreen(tester);
    await startApp(tester);

    await tester.tap(
      inHome(find.byTooltip('Marcar Responder e-mails como favorita')),
    );
    await tester.pumpAndSettle();

    await tester.tap(navIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoritas (1)'));
    await tester.pumpAndSettle();

    expect(inTasks(find.text('Responder e-mails')), findsOneWidget);
    expect(inTasks(find.text('Revisar contrato')), findsNothing);
  });
}
