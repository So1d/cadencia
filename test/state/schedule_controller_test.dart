import 'package:cadencia/core/load_status.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScheduleController build({
    List<Task> tasks = const [],
    List<CalendarEvent> events = const [],
    int failuresRemaining = 0,
  }) {
    return ScheduleController(
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
  }

  group('carga', () {
    test('começa carregando e termina em success', () async {
      final controller = build();
      expect(controller.status, LoadStatus.loading);

      await controller.init();

      expect(controller.status, LoadStatus.success);
      addTearDown(controller.dispose);
    });

    test('statusFor devolve empty quando a coleção está vazia', () async {
      final controller = build();
      await controller.init();

      expect(controller.statusFor(const []), LoadStatus.empty);
      expect(controller.statusFor([1]), LoadStatus.success);
      addTearDown(controller.dispose);
    });

    test('erro na primeira carga e sucesso no retry', () async {
      final controller = build(failuresRemaining: 1);
      await controller.init();
      expect(controller.status, LoadStatus.error);

      await controller.init();
      expect(controller.status, LoadStatus.success);
      addTearDown(controller.dispose);
    });
  });

  group('ordenação de tarefas', () {
    test('pendentes primeiro, depois data, prioridade e título', () async {
      final today = DateTime(2026, 11, 10);
      final done = Task(title: 'Feita', done: true, dueDate: today);
      final noDate = Task(title: 'Sem data');
      final tomorrow = Task(
        title: 'Amanhã',
        dueDate: today.add(const Duration(days: 1)),
      );
      final highToday = Task(
        title: 'Alta hoje',
        dueDate: today,
        priority: TaskPriority.high,
      );

      final controller = build(
        tasks: [done, noDate, tomorrow, highToday],
      );
      await controller.init();

      expect(
        controller.tasksSorted.map((task) => task.title),
        ['Alta hoje', 'Amanhã', 'Sem data', 'Feita'],
      );
      addTearDown(controller.dispose);
    });

    test('eventos do dia colocam dia inteiro primeiro', () async {
      final today = DateTime(2026, 11, 10);
      final controller = build(
        events: [
          CalendarEvent(
            title: 'Tarde',
            start: DateTime(2026, 11, 10, 14),
          ),
          CalendarEvent(
            title: 'Dia inteiro',
            start: today,
            allDay: true,
          ),
          CalendarEvent(
            title: 'Manhã',
            start: DateTime(2026, 11, 10, 9),
          ),
          CalendarEvent(
            title: 'Outro dia',
            start: DateTime(2026, 11, 11, 9),
          ),
        ],
      );
      await controller.init();

      final titles =
          controller.eventsOfDay(today).map((event) => event.title).toList();
      expect(titles, ['Dia inteiro', 'Manhã', 'Tarde']);
      expect(controller.eventsCountOfDay(today), 3);
      addTearDown(controller.dispose);
    });
  });

  group('operações', () {
    test('adiciona, edita, conclui e remove tarefa', () async {
      final controller = build();
      await controller.init();

      controller.addTask(
        title: 'Comprar pão',
        notes: '  integral  ',
        dueDate: DateTime(2026, 11, 10, 18),
        priority: TaskPriority.medium,
      );
      expect(controller.tasks, hasLength(1));
      final task = controller.tasks.single;
      expect(task.notes, 'integral');
      expect(task.dueDate, DateTime(2026, 11, 10));

      controller.toggleTask(task, true);
      expect(controller.tasks.single.done, isTrue);

      controller.updateTask(
        controller.tasks.single,
        title: 'Comprar pão e leite',
        priority: TaskPriority.high,
      );
      expect(controller.tasks.single.title, 'Comprar pão e leite');
      expect(controller.tasks.single.notes, isNull);
      expect(controller.tasks.single.dueDate, isNull);
      expect(controller.tasks.single.priority, TaskPriority.high);

      controller.removeTask(controller.tasks.single);
      expect(controller.tasks, isEmpty);
      addTearDown(controller.dispose);
    });

    test('adiciona, edita e remove evento', () async {
      final controller = build();
      await controller.init();

      controller.addEvent(
        title: 'Reunião',
        start: DateTime(2026, 11, 10, 9),
        end: DateTime(2026, 11, 10, 10),
        notes: '  pauta  ',
      );
      final event = controller.events.single;
      expect(event.notes, 'pauta');

      controller.updateEvent(
        event,
        title: 'Reunião de equipe',
        start: DateTime(2026, 11, 10, 10),
        allDay: true,
      );
      final updated = controller.events.single;
      expect(updated.title, 'Reunião de equipe');
      expect(updated.allDay, isTrue);
      expect(updated.end, isNull);
      expect(updated.notes, isNull);

      controller.removeEvent(updated);
      expect(controller.events, isEmpty);
      addTearDown(controller.dispose);
    });

    test('progresso geral e do dia', () async {
      final today = DateTime(2026, 11, 10);
      final controller = build(
        tasks: [
          Task(title: 'A', dueDate: today, done: true),
          Task(title: 'B', dueDate: today),
          Task(title: 'C'),
        ],
      );
      await controller.init();

      expect(controller.progress, closeTo(1 / 3, 0.001));
      expect(controller.progressOfDay(today), 0.5);
      expect(controller.progressOfDay(today.add(const Duration(days: 2))), 0);
      addTearDown(controller.dispose);
    });
  });
}
