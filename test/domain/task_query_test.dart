import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/domain/task_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a consulta inicial não filtra nada', () {
    const query = TaskQuery.empty;

    expect(query.text, isEmpty);
    expect(query.status, TaskStatusFilter.pending);
    expect(query.priorities, isEmpty);
    expect(query.due, TaskDueFilter.any);
    expect(query.onlyFavorites, isFalse);
    expect(query.activeCount, 0);
    expect(query.hasFilters, isFalse);
  });

  test('activeCount conta grupos, não itens', () {
    var query = TaskQuery.empty.copyWith(text: '  relatório ');
    expect(query.activeCount, 1, reason: 'texto conta uma vez');

    query = query.copyWith(
      priorities: {TaskPriority.high, TaskPriority.low},
    );
    expect(query.activeCount, 2, reason: 'duas prioridades ainda são um grupo');

    query = query.copyWith(due: TaskDueFilter.today, onlyFavorites: true);
    expect(query.activeCount, 4);

    query = query.copyWith(status: TaskStatusFilter.all);
    expect(query.activeCount, 5);
  });

  test('texto só com espaços não conta como filtro', () {
    expect(TaskQuery.empty.copyWith(text: '   ').activeCount, 0);
  });

  test('igualdade compara o conteúdo do Set, não a identidade', () {
    final a = TaskQuery.empty.copyWith(
      priorities: {TaskPriority.high, TaskPriority.low},
    );
    final b = TaskQuery.empty.copyWith(
      priorities: {TaskPriority.low, TaskPriority.high},
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == TaskQuery.empty, isFalse);
  });

  test('copyWith preserva o que não foi informado', () {
    final original = TaskQuery.empty.copyWith(
      text: 'pão',
      onlyFavorites: true,
      sort: TaskSort.title,
      due: TaskDueFilter.week,
    );

    final copia = original.copyWith(status: TaskStatusFilter.done);

    expect(copia.text, 'pão');
    expect(copia.onlyFavorites, isTrue);
    expect(copia.due, TaskDueFilter.week);
    expect(copia.sort, TaskSort.title);
    expect(copia.status, TaskStatusFilter.done);
  });

  test('cleared volta ao inicial e preserva a ordenação', () {
    final query = TaskQuery.empty.copyWith(
      text: 'pão',
      status: TaskStatusFilter.all,
      priorities: {TaskPriority.high},
      due: TaskDueFilter.today,
      onlyFavorites: true,
      sort: TaskSort.priority,
    );

    final limpa = query.cleared();

    expect(limpa, TaskQuery.empty.copyWith(sort: TaskSort.priority));
    expect(limpa.sort, TaskSort.priority, reason: 'ordem não esconde nada');
    expect(limpa.hasFilters, isFalse);
  });
}
