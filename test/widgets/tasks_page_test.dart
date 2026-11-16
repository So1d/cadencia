import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/presentation/pages/tasks_page.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<(ScheduleController, ProfileController)> controllers({
    List<Task> tasks = const [],
  }) async {
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(
        seed: tasks,
        latency: Duration.zero,
      ),
      eventRepository: FakeEventRepository(latency: Duration.zero),
    );
    final profile = ProfileController(
      FakeProfileRepository(latency: Duration.zero),
    );
    await schedule.init();
    await profile.load();
    return (schedule, profile);
  }

  /// Os quatro segmentos não cabem na largura: o seletor rola na horizontal.
  /// Antes de tocar, é preciso trazer o segmento para dentro da viewport.
  Future<void> tapSegment(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('filtra pendentes, concluídas e todas', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Pendente', priority: TaskPriority.high),
        Task(title: 'Feita', done: true),
      ],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Feita'), findsNothing);
    expect(find.text('Pendentes (1)'), findsOneWidget);
    expect(find.text('Feitas (1)'), findsOneWidget);

    await tapSegment(tester, 'Feitas (1)');

    expect(find.text('Feita'), findsOneWidget);
    expect(find.text('Pendente'), findsNothing);

    await tapSegment(tester, 'Todas');
    await tester.pumpAndSettle();

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Feita'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('checkbox conclui a tarefa', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(schedule.tasks.single.done, isTrue);
    expect(find.text('Pendentes (0)'), findsOneWidget);
    expect(find.text('Nenhuma tarefa pendente. Bom sinal.'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('lista vazia mostra convite para criar', (tester) async {
    final (schedule, profile) = await controllers();

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma tarefa pendente. Bom sinal.'), findsOneWidget);
    expect(find.text('Criar tarefa'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  /// Monta a relação de favoritos com as tarefas dos títulos informados, na
  /// ordem dada (o primeiro é o favorito mais recente).
  FavoritesController favoritesWith(
    ScheduleController schedule,
    List<String> titles,
  ) {
    return FavoritesController(
      initialIds: [
        for (final title in titles)
          schedule.tasks.firstWhere((task) => task.title == title).id,
      ],
    );
  }

  testWidgets('os quatro filtros não estouram em 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Estrelada'), Task(title: 'Comum')],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favoritesWith(schedule, ['Estrelada']),
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Favoritas (1)'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('estrela do tile alterna o favorito', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Tomar remédio', priority: TaskPriority.high)],
    );
    final favorites = FavoritesController();

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favorites,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(favorites.favoriteIds, isEmpty);
    expect(find.byTooltip('Marcar Tomar remédio como favorita'), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar Tomar remédio como favorita'));
    await tester.pumpAndSettle();

    expect(favorites.isFavorite(schedule.tasks.single.id), isTrue);
    expect(find.byTooltip('Remover Tomar remédio dos favoritos'), findsOneWidget);
    expect(find.text('Favoritas (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover Tomar remédio dos favoritos'));
    await tester.pumpAndSettle();

    expect(favorites.favoriteIds, isEmpty);
    expect(find.byTooltip('Marcar Tomar remédio como favorita'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('filtro Favoritas mostra só as estreladas, mais recente antes',
      (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Antiga'),
        Task(title: 'Recente'),
        Task(title: 'Comum'),
      ],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favoritesWith(schedule, ['Recente', 'Antiga']),
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tapSegment(tester, 'Favoritas (2)');

    expect(find.text('Recente'), findsOneWidget);
    expect(find.text('Antiga'), findsOneWidget);
    expect(find.text('Comum'), findsNothing);

    // A ordem é a do favorito, não a da agenda: a mais recente vem primeiro.
    expect(
      tester.getTopLeft(find.text('Recente')).dy,
      lessThan(tester.getTopLeft(find.text('Antiga')).dy),
    );

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('filtro Favoritas vazio explica como favoritar', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comum')],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tapSegment(tester, 'Favoritas (0)');

    expect(find.text('Comum'), findsNothing);
    expect(
      find.text(
        'Nenhuma tarefa favorita ainda. '
        'Toque na estrela de uma tarefa para destacá-la.',
      ),
      findsOneWidget,
    );

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('tocar na tarefa abre o detalhe', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comprar pão'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa'), findsOneWidget);
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });
}
