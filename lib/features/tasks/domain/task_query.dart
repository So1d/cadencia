import 'task_priority.dart';

/// Situação das tarefas que a lista mostra.
enum TaskStatusFilter {
  pending('Pendentes'),
  done('Feitas'),
  all('Todas');

  const TaskStatusFilter(this.label);

  final String label;
}

/// Recorte por data de vencimento.
///
/// "Atrasadas" olha só a data: uma tarefa feita com prazo vencido continua
/// aparecendo aqui se a situação escolhida for "Feitas". Quem decide esconder
/// concluídas é [TaskStatusFilter], não o prazo.
enum TaskDueFilter {
  any('Qualquer prazo'),
  today('Vence hoje'),
  week('Semana'),
  overdue('Atrasadas');

  const TaskDueFilter(this.label);

  final String label;
}

/// Critério de ordenação da lista.
enum TaskSort {
  smart('Padrão'),
  dueDate('Prazo'),
  priority('Prioridade'),
  title('A-Z');

  const TaskSort(this.label);

  final String label;
}

/// Tudo o que a pessoa escolheu na tela de tarefas, num objeto só.
///
/// Antes isso vivia espalhado em vários campos do `State`. Como valor imutável,
/// a consulta pode ser comparada, copiada e entregue a outra tela sem que
/// ninguém segure uma cópia que envelhece.
///
/// O que **não** é filtro: a ordenação. Ela muda a ordem, não esconde
/// tarefas, então não entra em [activeCount] e sobrevive a [cleared].
class TaskQuery {
  const TaskQuery({
    this.text = '',
    this.status = TaskStatusFilter.pending,
    this.priorities = const {},
    this.due = TaskDueFilter.any,
    this.onlyFavorites = false,
    this.sort = TaskSort.smart,
  });

  /// Consulta inicial da tela: pendentes, sem recortes, ordem padrão.
  static const TaskQuery empty = TaskQuery();

  /// Texto digitado no campo de busca.
  final String text;

  final TaskStatusFilter status;

  /// Prioridades marcadas. Vazio = todas.
  final Set<TaskPriority> priorities;

  final TaskDueFilter due;

  final bool onlyFavorites;

  final TaskSort sort;

  /// Quantos filtros escondem tarefas agora.
  ///
  /// A contagem é derivada dos campos: não há um contador guardado para
  /// esquecer de atualizar. Texto e prioridades contam como um cada, mesmo
  /// que a pessoa marque três prioridades.
  int get activeCount {
    var count = 0;
    if (text.trim().isNotEmpty) count++;
    if (status != TaskStatusFilter.pending) count++;
    if (priorities.isNotEmpty) count++;
    if (due != TaskDueFilter.any) count++;
    if (onlyFavorites) count++;
    return count;
  }

  bool get hasFilters => activeCount > 0;

  TaskQuery copyWith({
    String? text,
    TaskStatusFilter? status,
    Set<TaskPriority>? priorities,
    TaskDueFilter? due,
    bool? onlyFavorites,
    TaskSort? sort,
  }) {
    return TaskQuery(
      text: text ?? this.text,
      status: status ?? this.status,
      priorities: priorities ?? this.priorities,
      due: due ?? this.due,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
    );
  }

  /// Volta ao estado inicial de consulta, **preservando a ordenação**.
  ///
  /// Limpar filtros não deve desfazer uma escolha de ordem: ordem não esconde
  /// nada, é preferência de leitura.
  TaskQuery cleared() => TaskQuery(sort: sort);

  @override
  bool operator ==(Object other) {
    return other is TaskQuery &&
        other.text == text &&
        other.status == status &&
        other.due == due &&
        other.onlyFavorites == onlyFavorites &&
        other.sort == sort &&
        other.priorities.length == priorities.length &&
        other.priorities.containsAll(priorities);
  }

  @override
  int get hashCode => Object.hash(
        text,
        status,
        // Set não tem hash por conteúdo: sem isso, duas consultas iguais com
        // prioridades em ordem diferente teriam hashes diferentes.
        Object.hashAllUnordered(priorities),
        due,
        onlyFavorites,
        sort,
      );

  @override
  String toString() => 'TaskQuery(text: "$text", status: ${status.name}, '
      'priorities: $priorities, due: ${due.name}, '
      'favorites: $onlyFavorites, sort: ${sort.name})';
}
