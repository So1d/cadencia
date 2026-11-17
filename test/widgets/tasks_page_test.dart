import 'package:cadencia/core/utils/date_helpers.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/domain/task_query.dart';
import 'package:cadencia/features/tasks/presentation/pages/tasks_page.dart';
import 'package:cadencia/features/tasks/presentation/task_query_controller.dart';
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

  /// Monta a página com os escopos e devolve a consulta, para o teste
  /// inspecionar o estado (e não só o que está na tela).
  Future<TaskQueryController> pumpTasks(
    WidgetTester tester, {
    required ScheduleController schedule,
    required ProfileController profile,
    FavoritesController? favorites,
  }) async {
    final query = TaskQueryController();
    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favorites,
        taskQuery: query,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();
    return query;
  }

  /// Monta a relação de favoritos com as tarefas dos títulos informados, na
  /// ordem dada (o primeiro é o favorito mais recente).
  FavoritesController favoritesWith(
    ScheduleController schedule,
    List<String> titles,
  ) {
    return buildFavorites(
      seed: [
        for (final title in titles)
          schedule.tasks.firstWhere((task) => task.title == title).id,
      ],
    );
  }

  testWidgets('abre em pendentes e alterna a situação', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Pendente', priority: TaskPriority.high),
        Task(title: 'Feita', done: true),
      ],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Feita'), findsNothing);
    expect(find.text('1 tarefa encontrada'), findsOneWidget);

    await tester.tap(find.text('Feitas'));
    await tester.pumpAndSettle();

    expect(find.text('Feita'), findsOneWidget);
    expect(find.text('Pendente'), findsNothing);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    expect(find.text('Pendente'), findsOneWidget);
    expect(find.text('Feita'), findsOneWidget);
    expect(find.text('2 tarefas encontradas'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('checkbox conclui a tarefa', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(schedule.tasks.single.done, isTrue);
    expect(find.text('0 tarefas encontradas'), findsOneWidget);
    expect(find.text('Nenhuma tarefa pendente. Bom sinal.'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('lista vazia mostra convite para criar', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers();

    await pumpTasks(tester, schedule: schedule, profile: profile);

    expect(find.text('Nenhuma tarefa pendente. Bom sinal.'), findsOneWidget);
    expect(find.text('Criar tarefa'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('busca espera o silêncio antes de filtrar', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Enviar relatório mensal'),
        Task(title: 'Comprar pão'),
      ],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    await tester.enterText(find.byType(TextField), 'relatorio');
    await tester.pump();

    // Ainda dentro da janela de silêncio: a lista não mudou.
    expect(find.text('Comprar pão'), findsOneWidget);
    expect(find.text('2 tarefas encontradas'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));

    // "relatorio" acha "relatório": a comparação ignora acento.
    expect(find.text('Enviar relatório mensal'), findsOneWidget);
    expect(find.text('Comprar pão'), findsNothing);
    expect(find.text('1 tarefa encontrada'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('busca com duas palavras exige as duas', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Enviar relatório mensal'),
        Task(title: 'Comprar pão'),
      ],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    await tester.enterText(find.byType(TextField), 'relatorio enviar');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Enviar relatório mensal'), findsOneWidget);
    expect(find.text('1 tarefa encontrada'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'relatorio comprar');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nenhuma tarefa combina com essa busca.'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('limpar filtros esvazia o campo e a consulta', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Enviar relatório mensal'),
        Task(title: 'Comprar pão'),
      ],
    );

    final query = await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
    );

    await tester.enterText(find.byType(TextField), 'relatorio');
    await tester.pump(const Duration(milliseconds: 300));
    expect(query.query.text, 'relatorio');

    await tester.tap(find.text('Limpar filtros (1)'));
    await tester.pumpAndSettle();

    expect(query.query.text, isEmpty);
    expect(query.query.hasFilters, isFalse);
    // O campo acompanha o estado: não fica mostrando um texto que já foi
    // limpo.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Comprar pão'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('chip de prioridade soma recortes (OU dentro do grupo)',
      (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Tarefa alta', priority: TaskPriority.high),
        Task(title: 'Tarefa média', priority: TaskPriority.medium),
        Task(title: 'Tarefa baixa', priority: TaskPriority.low),
      ],
    );

    final query = await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
    );

    await tester.tap(find.widgetWithText(FilterChip, 'Alta'));
    await tester.pumpAndSettle();

    expect(query.query.priorities, {TaskPriority.high});
    expect(find.text('Tarefa alta'), findsOneWidget);
    expect(find.text('Tarefa média'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Média'));
    await tester.pumpAndSettle();

    expect(query.query.priorities, {TaskPriority.high, TaskPriority.medium});
    expect(find.text('Tarefa média'), findsOneWidget);
    expect(find.text('Tarefa baixa'), findsNothing);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('prazo: hoje e atrasadas', (tester) async {
    useTallScreen(tester);
    final hoje = dateOnly(DateTime.now());

    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Para hoje', dueDate: hoje),
        Task(title: 'Atrasada', dueDate: hoje.subtract(const Duration(days: 2))),
        Task(title: 'Sem prazo'),
      ],
    );

    final query = await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
    );

    await tester.tap(find.text('Vence hoje'));
    await tester.pumpAndSettle();

    expect(query.query.due, TaskDueFilter.today);
    expect(find.text('Para hoje'), findsOneWidget);
    expect(find.text('Atrasada'), findsNothing);

    await tester.tap(find.text('Atrasadas'));
    await tester.pumpAndSettle();

    expect(query.query.due, TaskDueFilter.overdue);
    expect(find.text('Atrasada'), findsOneWidget);
    expect(find.text('Para hoje'), findsNothing);

    // Tocar de novo no prazo marcado volta a "qualquer prazo".
    await tester.tap(find.text('Atrasadas'));
    await tester.pumpAndSettle();

    expect(query.query.due, TaskDueFilter.any);
    expect(find.text('Sem prazo'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('ordenação A-Z muda a ordem da lista', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Zebra', priority: TaskPriority.high),
        Task(title: 'Abacaxi', priority: TaskPriority.low),
      ],
    );

    final query = await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
    );

    // Padrão: prioridade alta primeiro.
    expect(
      tester.getTopLeft(find.text('Zebra')).dy,
      lessThan(tester.getTopLeft(find.text('Abacaxi')).dy),
    );

    await tester.tap(find.byTooltip('Ordenar tarefas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A-Z').last);
    await tester.pumpAndSettle();

    expect(query.query.sort, TaskSort.title);
    expect(
      tester.getTopLeft(find.text('Abacaxi')).dy,
      lessThan(tester.getTopLeft(find.text('Zebra')).dy),
    );

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('filtro Favoritas mostra só as estreladas, mais recente antes',
      (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [
        Task(title: 'Antiga'),
        Task(title: 'Recente'),
        Task(title: 'Comum'),
      ],
    );

    final favorites = favoritesWith(schedule, ['Recente', 'Antiga']);
    await favorites.load();

    await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
      favorites: favorites,
    );

    await tester.tap(find.text('Favoritas (2)'));
    await tester.pumpAndSettle();

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
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comum')],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    await tester.tap(find.text('Favoritas (0)'));
    await tester.pumpAndSettle();

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

  testWidgets('estrela do tile alterna o favorito e a contagem', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Tomar remédio', priority: TaskPriority.high)],
    );
    final favorites = buildFavorites();

    await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
      favorites: favorites,
    );

    expect(favorites.favoriteIds, isEmpty);
    expect(find.text('Favoritas (0)'), findsOneWidget);
    expect(find.byTooltip('Marcar Tomar remédio como favorita'), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar Tomar remédio como favorita'));
    await tester.pumpAndSettle();

    expect(favorites.isFavorite(schedule.tasks.single.id), isTrue);
    expect(find.text('Favoritas (1)'), findsOneWidget);
    expect(find.byTooltip('Remover Tomar remédio dos favoritos'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('tocar na tarefa abre o detalhe', (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    await tester.tap(find.text('Comprar pão'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa'), findsOneWidget);
    expect(find.text('Pendente'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('chips e ações respeitam os alvos e rótulos de acessibilidade',
      (tester) async {
    useTallScreen(tester);
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Estrelada'), Task(title: 'Comum')],
    );
    final favorites = favoritesWith(schedule, ['Estrelada']);
    await favorites.load();

    await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
      favorites: favorites,
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('filtros não estouram em 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Estrelada'), Task(title: 'Comum')],
    );
    final favorites = favoritesWith(schedule, ['Estrelada']);
    await favorites.load();

    await pumpTasks(
      tester,
      schedule: schedule,
      profile: profile,
      favorites: favorites,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Favoritas (1)'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('filtros não estouram com fonte 200% em 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Estrelada'), Task(title: 'Comum')],
    );

    await pumpTasks(tester, schedule: schedule, profile: profile);

    expect(tester.takeException(), isNull);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });
}
