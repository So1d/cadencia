import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskPriority', () {
    test('fromValue devolve a prioridade certa', () {
      expect(TaskPriority.fromValue(0), TaskPriority.low);
      expect(TaskPriority.fromValue(1), TaskPriority.medium);
      expect(TaskPriority.fromValue(2), TaskPriority.high);
    });

    test('fromValue desconhecido cai em medium', () {
      expect(TaskPriority.fromValue(99), TaskPriority.medium);
      expect(TaskPriority.fromValue(-1), TaskPriority.medium);
    });
  });

  group('Task', () {
    test('ida e volta por JSON preserva os campos', () {
      final task = Task(
        id: 't1',
        title: 'Estudar Flutter',
        notes: 'Capítulo 4',
        dueDate: DateTime(2026, 11, 10),
        done: true,
        priority: TaskPriority.high,
      );

      final copy = Task.fromJson(task.toJson());

      expect(copy.id, 't1');
      expect(copy.title, 'Estudar Flutter');
      expect(copy.notes, 'Capítulo 4');
      expect(copy.dueDate, DateTime(2026, 11, 10));
      expect(copy.done, isTrue);
      expect(copy.priority, TaskPriority.high);
    });

    test('fromJson tolera campos ausentes e inválidos', () {
      final task = Task.fromJson({
        'title': 'Sem id',
        'priority': 'alta',
        'due_date': 'não é data',
      });

      expect(task.id, isNotEmpty);
      expect(task.title, 'Sem id');
      expect(task.priority, TaskPriority.medium);
      expect(task.dueDate, isNull);
      expect(task.done, isFalse);
    });

    test('copyWith limpa observações e data quando pedido', () {
      final task = Task(
        title: 'X',
        notes: 'nota',
        dueDate: DateTime(2026, 1, 1),
        priority: TaskPriority.low,
      );

      final copy = task.copyWith(
        title: 'Y',
        clearNotes: true,
        clearDueDate: true,
        done: true,
      );

      expect(copy.title, 'Y');
      expect(copy.notes, isNull);
      expect(copy.dueDate, isNull);
      expect(copy.done, isTrue);
      expect(copy.id, task.id);
    });
  });
}
