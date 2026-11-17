import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/search_text.dart';
import 'task.dart';
import 'task_query.dart';

/// Aplica a consulta ao catálogo e devolve uma **lista nova**, filtrada e
/// ordenada.
///
/// É função pura: os mesmos argumentos produzem o mesmo resultado, sem
/// `BuildContext`, sem `Provider` e sem I/O. Por isso a regra pode ser testada
/// em milissegundos, sem subir o app.
///
/// * [tasks] é o catálogo; ele **não** é alterado (a ordenação acontece numa
///   cópia).
/// * [favoriteIds] vem do `FavoritesController`, na ordem de escolha; a tarefa
///   em si não carrega o booleano.
/// * [now] existe para o teste ter um "hoje" fixo.
List<Task> applyTaskQuery(
  List<Task> tasks,
  TaskQuery query, {
  List<String> favoriteIds = const [],
  DateTime? now,
}) {
  final hoje = dateOnly(now ?? DateTime.now());
  final termos = searchTerms(query.text);
  final favoritos = favoriteIds.toSet();

  final resultado = <Task>[];
  for (final task in tasks) {
    if (!_casaSituacao(task, query.status)) continue;
    if (query.onlyFavorites && !favoritos.contains(task.id)) continue;
    if (query.priorities.isNotEmpty &&
        !query.priorities.contains(task.priority)) {
      continue;
    }
    if (!_casaPrazo(task, query.due, hoje)) continue;
    if (!_casaTexto(task, termos)) continue;
    resultado.add(task);
  }

  // `sort` na cópia, nunca no catálogo original.
  if (query.onlyFavorites && query.sort == TaskSort.smart) {
    // No filtro de favoritas, a ordem padrão é a de escolha: a marcada por
    // último vem primeiro. É a leitura natural de uma coleção de favoritos, e
    // as outras ordenações continuam a um toque no menu.
    final posicao = {
      for (var i = 0; i < favoriteIds.length; i++) favoriteIds[i]: i,
    };
    resultado.sort(
      (a, b) => (posicao[a.id] ?? favoriteIds.length)
          .compareTo(posicao[b.id] ?? favoriteIds.length),
    );
  } else {
    resultado.sort(_comparador(query.sort));
  }
  return List.unmodifiable(resultado);
}

bool _casaSituacao(Task task, TaskStatusFilter status) => switch (status) {
      TaskStatusFilter.pending => !task.done,
      TaskStatusFilter.done => task.done,
      TaskStatusFilter.all => true,
    };

/// E entre grupos, OU dentro do grupo: quem marca duas prioridades aceita
/// tarefas de qualquer uma delas.
bool _casaPrazo(Task task, TaskDueFilter due, DateTime hoje) {
  final prazo = task.dueDate;
  return switch (due) {
    TaskDueFilter.any => true,
    TaskDueFilter.today => prazo != null && mesmoDia(prazo, hoje),
    TaskDueFilter.week => prazo != null &&
        !prazo.isBefore(hoje) &&
        !prazo.isAfter(hoje.add(const Duration(days: 7))),
    TaskDueFilter.overdue => prazo != null && prazo.isBefore(hoje),
  };
}

/// Todas as palavras precisam aparecer no título ou nas observações.
///
/// A comparação é feita sem acento e sem caixa: "relatorio" acha "Relatório".
bool _casaTexto(Task task, List<String> termos) {
  if (termos.isEmpty) return true;
  final alvo = normalizeForSearch('${task.title} ${task.notes ?? ''}');
  for (final termo in termos) {
    if (!alvo.contains(termo)) return false;
  }
  return true;
}

int Function(Task, Task) _comparador(TaskSort sort) => switch (sort) {
      TaskSort.smart => _smart,
      TaskSort.dueDate => _byDueDate,
      TaskSort.priority => _byPriority,
      TaskSort.title => _byTitle,
    };

/// Mesma ordem da agenda: pendentes primeiro, prazo mais próximo, prioridade
/// alta, título.
int _smart(Task a, Task b) {
  if (a.done != b.done) return a.done ? 1 : -1;
  final byDue = _compareDue(a, b);
  return byDue != 0 ? byDue : _byPriorityThenTitle(a, b);
}

int _byDueDate(Task a, Task b) {
  final byDue = _compareDue(a, b);
  return byDue != 0 ? byDue : _byPriorityThenTitle(a, b);
}

int _byPriority(Task a, Task b) {
  final byPriority = b.priority.value.compareTo(a.priority.value);
  if (byPriority != 0) return byPriority;
  final byDue = _compareDue(a, b);
  return byDue != 0 ? byDue : _byTitle(a, b);
}

/// Sem data vai para o fim: quem não tem prazo não atrasa.
int _compareDue(Task a, Task b) {
  final aDue = a.dueDate;
  final bDue = b.dueDate;
  if (aDue == null && bDue == null) return 0;
  if (aDue == null) return 1;
  if (bDue == null) return -1;
  return aDue.compareTo(bDue);
}

int _byPriorityThenTitle(Task a, Task b) {
  final byPriority = b.priority.value.compareTo(a.priority.value);
  return byPriority != 0 ? byPriority : _byTitle(a, b);
}

/// Desempate final por título, com o id em último caso.
///
/// Sem desempate, `List.sort` deixa empates em ordem imprevisível, e o teste
/// (ou a pessoa) vê a lista mudar sem nenhum dado ter mudado.
int _byTitle(Task a, Task b) {
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
}
