import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:cadencia/features/tasks/domain/task_query.dart';
import 'package:cadencia/features/tasks/presentation/task_query_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('começa na consulta inicial', () {
    final controller = TaskQueryController();

    expect(controller.query, TaskQuery.empty);
  });

  test('notifica quando a consulta muda', () {
    final controller = TaskQueryController();
    var notificacoes = 0;
    controller.addListener(() => notificacoes++);

    controller.setText('pão');

    expect(controller.query.text, 'pão');
    expect(notificacoes, 1);
  });

  test('valor igual não notifica', () {
    final controller = TaskQueryController();
    var notificacoes = 0;
    controller.addListener(() => notificacoes++);

    controller.setStatus(TaskStatusFilter.pending);
    controller.setText('');

    expect(notificacoes, 0);
  });

  test('toggleDue liga e desliga o mesmo prazo', () {
    final controller = TaskQueryController();

    controller.toggleDue(TaskDueFilter.today);
    expect(controller.query.due, TaskDueFilter.today);

    controller.toggleDue(TaskDueFilter.week);
    expect(controller.query.due, TaskDueFilter.week);

    controller.toggleDue(TaskDueFilter.week);
    expect(controller.query.due, TaskDueFilter.any);
  });

  test('togglePriority soma e tira', () {
    final controller = TaskQueryController();

    controller.togglePriority(TaskPriority.high);
    controller.togglePriority(TaskPriority.low);

    expect(
      controller.query.priorities,
      {TaskPriority.high, TaskPriority.low},
    );

    controller.togglePriority(TaskPriority.high);

    expect(controller.query.priorities, {TaskPriority.low});
  });

  test('limpar preserva a ordenação', () {
    final controller = TaskQueryController()
      ..setSort(TaskSort.priority)
      ..setText('pão')
      ..setStatus(TaskStatusFilter.all)
      ..toggleOnlyFavorites();

    controller.clear();

    expect(controller.query, TaskQuery.empty.copyWith(sort: TaskSort.priority));
  });

  test('showOnly começa do zero e liga um recorte', () {
    final controller = TaskQueryController()
      ..setText('pão')
      ..setStatus(TaskStatusFilter.all)
      ..setSort(TaskSort.title)
      ..toggleDue(TaskDueFilter.week);

    controller.showOnly(priority: TaskPriority.high);

    expect(controller.query.text, isEmpty);
    expect(controller.query.status, TaskStatusFilter.pending);
    expect(controller.query.due, TaskDueFilter.any);
    expect(controller.query.priorities, {TaskPriority.high});
    expect(controller.query.sort, TaskSort.title, reason: 'ordem é preferência');
  });
}
