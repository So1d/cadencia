import 'package:cadencia/features/events/data/fake_event_repository.dart';
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

    await tester.tap(find.text('Feitas (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Feita'), findsOneWidget);
    expect(find.text('Pendente'), findsNothing);

    await tester.tap(find.text('Todas'));
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
}
