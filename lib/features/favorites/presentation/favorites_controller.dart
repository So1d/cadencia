import 'package:flutter/foundation.dart';

/// As tarefas favoritas do Cadência, em memória.
///
/// É a **fonte única da verdade** da seleção: nenhuma tela guarda o próprio
/// booleano, todas perguntam para cá. Duas estruturas trabalham juntas:
///
/// * `List<String> _ordered` preserva a ordem de escolha, com o favorito mais
///   recente no índice 0 — é a ordem que a seção "Favoritas" mostra;
/// * `Set<String> _ids` responde [isFavorite] em O(1), consulta feita no build
///   de cada linha da lista.
///
/// Guardamos **ids**, não `Task`: a tarefa pertence à agenda
/// ([ScheduleController]), e duplicar a entidade aqui faria o favorito ficar
/// desatualizado depois de uma edição. O que é nosso é a pertinência e a ordem.
///
/// Estado só em memória, como pede a Etapa 1: reiniciar o app limpa a seleção.
/// Persistir é assunto de uma etapa posterior.
class FavoritesController extends ChangeNotifier {
  FavoritesController({Iterable<String> initialIds = const []})
      : _ordered = List.unmodifiable(initialIds.toSet().toList()),
        _ids = {...initialIds};

  List<String> _ordered;
  Set<String> _ids;

  /// Ids favoritados, do mais recente para o mais antigo.
  ///
  /// Somente leitura: quem quiser mudar passa por [toggle] ou [remove].
  List<String> get favoriteIds => _ordered;

  /// Consulta em tempo constante, usada no build de cada linha.
  bool isFavorite(String taskId) => _ids.contains(taskId);

  /// Alterna o favorito e devolve `true` se a tarefa passou a ser favorita.
  ///
  /// Novas favoritas entram no índice 0; as demais mantêm a ordem relativa.
  bool toggle(String taskId) {
    if (_ids.contains(taskId)) {
      _ordered = List.unmodifiable(
        _ordered.where((id) => id != taskId),
      );
      _ids = {..._ids}..remove(taskId);
      notifyListeners();
      return false;
    }

    _ordered = List.unmodifiable([
      taskId,
      ..._ordered.where((id) => id != taskId),
    ]);
    _ids = {..._ids, taskId};
    notifyListeners();
    return true;
  }

  /// Tira da relação sem alternar — usado quando a tarefa é excluída.
  void remove(String taskId) {
    if (!_ids.contains(taskId)) return;
    _ordered = List.unmodifiable(_ordered.where((id) => id != taskId));
    _ids = {..._ids}..remove(taskId);
    notifyListeners();
  }
}
