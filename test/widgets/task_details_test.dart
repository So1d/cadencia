import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/presentation/pages/tasks_page.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_app.dart';

/// Testes A e B da Etapa 1: a estrela da listagem e a do detalhe são o mesmo
/// estado visto de dois lugares.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<(ScheduleController, ProfileController)> controllers({
    List<Task> tasks = const [],
  }) async {
    final schedule = ScheduleController(
      taskRepository: FakeTaskRepository(seed: tasks, latency: Duration.zero),
      eventRepository: FakeEventRepository(latency: Duration.zero),
    );
    final profile = ProfileController(
      FakeProfileRepository(latency: Duration.zero),
    );
    await schedule.init();
    await profile.load();
    return (schedule, profile);
  }

  testWidgets('A: marcar na listagem já aparece marcado no detalhe',
      (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
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

    await tester.tap(find.byTooltip('Marcar Comprar pão como favorita'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comprar pão'));
    await tester.pumpAndSettle();

    expect(find.text('Tarefa'), findsOneWidget);
    expect(
      find.byTooltip('Remover Comprar pão dos favoritos'),
      findsOneWidget,
    );

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('B: desmarcar no detalhe reflete na listagem', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );
    final favorites = FavoritesController(
      initialIds: [schedule.tasks.single.id],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favorites,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favoritas (1)'), findsOneWidget);

    await tester.tap(find.text('Comprar pão'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remover Comprar pão dos favoritos'));
    await tester.pumpAndSettle();

    expect(favorites.favoriteIds, isEmpty);

    // Volta para a listagem: ela já reflete a remoção, sem toque nenhum.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Favoritas (0)'), findsOneWidget);
    expect(find.byTooltip('Marcar Comprar pão como favorita'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('concluir no detalhe marca a tarefa também na listagem',
      (tester) async {
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

    expect(find.text('Pendente'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(schedule.tasks.single.done, isTrue);
    expect(find.text('Concluída'), findsOneWidget);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });

  testWidgets('excluir no detalhe tira a tarefa dos favoritos', (tester) async {
    final (schedule, profile) = await controllers(
      tasks: [Task(title: 'Comprar pão')],
    );
    final favorites = FavoritesController(
      initialIds: [schedule.tasks.single.id],
    );

    await tester.pumpWidget(
      wrapWithScopes(
        schedule: schedule,
        favorites: favorites,
        profile: profile,
        home: const TasksPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comprar pão'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Excluir'),
      ),
    );
    await tester.pumpAndSettle();

    expect(schedule.tasks, isEmpty);
    expect(favorites.favoriteIds, isEmpty);

    addTearDown(schedule.dispose);
    addTearDown(profile.dispose);
  });
}
