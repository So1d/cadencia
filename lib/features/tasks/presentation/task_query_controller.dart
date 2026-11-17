import 'package:flutter/foundation.dart';

import '../domain/task_priority.dart';
import '../domain/task_query.dart';

/// A consulta da tela de tarefas.
///
/// Guarda **só** o que a pessoa escolheu. O catálogo continua na agenda
/// (`ScheduleController`) e a lista visível é calculada no build por
/// [applyTaskQuery], a partir do catálogo, da consulta e dos favoritos.
///
/// Guardar o resultado aqui seria pedir para ele envelhecer: bastaria favoritar
/// uma tarefa em outra aba para a lista ficar desatualizada.
class TaskQueryController extends ChangeNotifier {
  TaskQuery _query = TaskQuery.empty;

  TaskQuery get query => _query;

  /// Troca a consulta inteira. Valor igual não notifica: sem isso, cada toque
  /// que não muda nada reconstruiria a tela à toa.
  void update(TaskQuery next) {
    if (next == _query) return;
    _query = next;
    notifyListeners();
  }

  void setText(String text) => update(_query.copyWith(text: text));

  void setStatus(TaskStatusFilter status) =>
      update(_query.copyWith(status: status));

  void setSort(TaskSort sort) => update(_query.copyWith(sort: sort));

  /// Tocar no prazo já marcado desliga o recorte (volta para "qualquer").
  void toggleDue(TaskDueFilter due) => update(
        _query.copyWith(
          due: _query.due == due ? TaskDueFilter.any : due,
        ),
      );

  void togglePriority(TaskPriority priority) {
    final next = {..._query.priorities};
    if (!next.remove(priority)) next.add(priority);
    update(_query.copyWith(priorities: next));
  }

  void toggleOnlyFavorites() =>
      update(_query.copyWith(onlyFavorites: !_query.onlyFavorites));

  /// Limpa os filtros e mantém a ordenação escolhida.
  void clear() => update(_query.cleared());

  /// Atalho de outra tela: começa do zero e liga **um** recorte.
  ///
  /// Diferente de [togglePriority], que soma ou tira um item do que já estava
  /// escolhido. O atalho da Home quer "só isto", não "isto também".
  void showOnly({TaskPriority? priority, TaskDueFilter? due}) {
    update(
      TaskQuery(
        sort: _query.sort,
        priorities: priority == null ? const {} : {priority},
        due: due ?? TaskDueFilter.any,
      ),
    );
  }
}
