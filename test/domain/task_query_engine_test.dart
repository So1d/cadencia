import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/domain/task_query.dart';
import 'package:cadencia/features/tasks/domain/task_query_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // "Hoje" fixo: o teste não pode depender da data em que roda.
  final now = DateTime(2026, 11, 17, 10);
  final hoje = DateTime(2026, 11, 17);

  Task task(
    String id,
    String title, {
    bool done = false,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? notes,
  }) {
    return Task(
      id: id,
      title: title,
      done: done,
      priority: priority,
      dueDate: dueDate,
      notes: notes,
    );
  }

  List<String> titles(List<Task> tasks) => [for (final t in tasks) t.title];

  test('situação filtra pendentes, feitas e todas', () {
    final tasks = [
      task('1', 'Pendente'),
      task('2', 'Feita', done: true),
    ];

    expect(
      titles(applyTaskQuery(tasks, TaskQuery.empty, now: now)),
      ['Pendente'],
    );
    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(status: TaskStatusFilter.done),
        now: now,
      )),
      ['Feita'],
    );
    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(status: TaskStatusFilter.all),
        now: now,
      )),
      ['Pendente', 'Feita'],
    );
  });

  test('só favoritas usa a relação de ids', () {
    final tasks = [task('1', 'Favorita'), task('2', 'Comum')];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(onlyFavorites: true),
      favoriteIds: const ['1'],
      now: now,
    );

    expect(titles(result), ['Favorita']);
  });

  test('prioridades combinam com OU dentro do grupo', () {
    final tasks = [
      task('1', 'Alta', priority: TaskPriority.high),
      task('2', 'Média', priority: TaskPriority.medium),
      task('3', 'Baixa', priority: TaskPriority.low),
    ];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(
        priorities: {TaskPriority.high, TaskPriority.low},
      ),
      now: now,
    );

    expect(titles(result), unorderedEquals(['Alta', 'Baixa']));
  });

  test('texto ignora acento e caixa', () {
    final tasks = [task('1', 'Enviar Relatório Mensal'), task('2', 'Pão')];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(text: 'RELATORIO'),
      now: now,
    );

    expect(titles(result), ['Enviar Relatório Mensal']);
  });

  test('texto procura também nas observações', () {
    final tasks = [
      task('1', 'Comprar presente', notes: 'aniversário da Ana'),
      task('2', 'Comprar pão'),
    ];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(text: 'ana'),
      now: now,
    );

    expect(titles(result), ['Comprar presente']);
  });

  test('texto exige todas as palavras', () {
    final tasks = [
      task('1', 'Enviar relatório mensal'),
      task('2', 'Enviar convite'),
    ];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(text: 'enviar relatorio'),
      now: now,
    );

    expect(titles(result), ['Enviar relatório mensal']);
  });

  test('prazo: hoje, semana e atrasadas', () {
    final tasks = [
      task('1', 'Atrasada', dueDate: hoje.subtract(const Duration(days: 1))),
      task('2', 'Hoje', dueDate: hoje),
      task('3', 'Daqui a três dias', dueDate: hoje.add(const Duration(days: 3))),
      task('4', 'Longe', dueDate: hoje.add(const Duration(days: 30))),
      task('5', 'Sem prazo'),
    ];

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(due: TaskDueFilter.today),
        now: now,
      )),
      ['Hoje'],
    );

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(due: TaskDueFilter.week),
        now: now,
      )),
      unorderedEquals(['Hoje', 'Daqui a três dias']),
    );

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(due: TaskDueFilter.overdue),
        now: now,
      )),
      ['Atrasada'],
    );
  });

  test('ordenação padrão: prazo mais próximo e prioridade desempatam', () {
    final tasks = [
      task('1', 'Sem prazo', priority: TaskPriority.high),
      task('2', 'Amanhã', dueDate: hoje.add(const Duration(days: 1)),
          priority: TaskPriority.low),
      task('3', 'Hoje baixa', dueDate: hoje, priority: TaskPriority.low),
      task('4', 'Hoje alta', dueDate: hoje, priority: TaskPriority.high),
    ];

    expect(
      titles(applyTaskQuery(tasks, TaskQuery.empty, now: now)),
      ['Hoje alta', 'Hoje baixa', 'Amanhã', 'Sem prazo'],
    );
  });

  test('ordenação por prazo, prioridade e título', () {
    final tasks = [
      task('1', 'Zebra', priority: TaskPriority.high),
      task('2', 'Abacaxi', priority: TaskPriority.low),
      task('3', 'Melancia', dueDate: hoje, priority: TaskPriority.medium),
    ];

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(sort: TaskSort.title),
        now: now,
      )),
      ['Abacaxi', 'Melancia', 'Zebra'],
    );

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(sort: TaskSort.priority),
        now: now,
      )),
      ['Zebra', 'Melancia', 'Abacaxi'],
    );

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(sort: TaskSort.dueDate),
        now: now,
      )),
      ['Melancia', 'Zebra', 'Abacaxi'],
    );
  });

  test('empate de ordenação desempata por título, sem ordem imprevisível', () {
    final tasks = [
      task('1', 'B'),
      task('2', 'C'),
      task('3', 'A'),
    ];

    expect(
      titles(applyTaskQuery(
        tasks,
        TaskQuery.empty.copyWith(sort: TaskSort.priority),
        now: now,
      )),
      ['A', 'B', 'C'],
    );
  });

  test('no filtro de favoritas, a ordem padrão é a de escolha', () {
    final tasks = [
      task('1', 'Antiga'),
      task('2', 'Recente'),
    ];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(onlyFavorites: true),
      favoriteIds: const ['2', '1'],
      now: now,
    );

    expect(titles(result), ['Recente', 'Antiga']);
  });

  test('no filtro de favoritas, outra ordenação manda', () {
    final tasks = [
      task('1', 'Zebra'),
      task('2', 'Abacaxi'),
    ];

    final result = applyTaskQuery(
      tasks,
      TaskQuery.empty.copyWith(onlyFavorites: true, sort: TaskSort.title),
      favoriteIds: const ['1', '2'],
      now: now,
    );

    expect(titles(result), ['Abacaxi', 'Zebra']);
  });

  test('o catálogo original não é alterado', () {
    final original = [
      task('1', 'B', priority: TaskPriority.low),
      task('2', 'A', priority: TaskPriority.high),
    ];
    final copia = [...original];

    applyTaskQuery(
      original,
      TaskQuery.empty.copyWith(sort: TaskSort.title),
      now: now,
    );

    expect(titles(original), titles(copia));
  });

  test('sem tarefas devolve lista vazia e imutável', () {
    final result = applyTaskQuery(const [], TaskQuery.empty, now: now);

    expect(result, isEmpty);
    expect(() => result.add(task('x', 'x')), throwsUnsupportedError);
  });
}
