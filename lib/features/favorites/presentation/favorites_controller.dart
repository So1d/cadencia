import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/repositories/favorites_repository.dart';

/// As tarefas favoritas do Cadência.
///
/// É a **fonte única da verdade** da seleção: nenhuma tela guarda o próprio
/// booleano, todas perguntam para cá. Duas estruturas trabalham juntas:
///
/// * `List<String> _ordered` preserva a ordem de escolha, com o favorito mais
///   recente no índice 0 — é a ordem que a seção "Favoritas" mostra;
/// * `Set<String> _ids` responde [isFavorite] em O(1), consulta feita no build
///   de cada linha.
///
/// Guardamos **ids**, não `Task`: a tarefa pertence à agenda
/// ([ScheduleController]), e duplicar a entidade aqui faria o favorito ficar
/// desatualizado depois de uma edição. O que é nosso é a pertinência e a ordem,
/// e é exatamente isso que o repositório grava no aparelho.
class FavoritesController extends ChangeNotifier {
  FavoritesController({required this.repository});

  final FavoritesRepository repository;

  List<String> _ordered = const [];
  Set<String> _ids = const {};

  /// Ids favoritados, do mais recente para o mais antigo.
  ///
  /// Somente leitura: quem quiser mudar passa por [toggle] ou [remove].
  List<String> get favoriteIds => _ordered;

  /// Consulta em tempo constante, usada no build de cada linha.
  bool isFavorite(String taskId) => _ids.contains(taskId);

  /// Carrega a relação salva no aparelho.
  ///
  /// Falha de leitura não pode derrubar a tela: nesse caso começamos vazio e a
  /// próxima marcação regrava.
  Future<void> load() async {
    try {
      final ids = await repository.fetchAll();
      _ordered = List.unmodifiable(ids.toSet().toList());
      _ids = {...ids};
      notifyListeners();
    } catch (_) {
      _ordered = const [];
      _ids = const {};
      notifyListeners();
    }
  }

  /// Alterna o favorito e devolve `true` se a tarefa passou a ser favorita.
  ///
  /// Novas favoritas entram no índice 0; as demais mantêm a ordem relativa.
  bool toggle(String taskId) {
    if (_ids.contains(taskId)) {
      _ordered = List.unmodifiable(
        _ordered.where((id) => id != taskId),
      );
      _ids = {..._ids}..remove(taskId);
    } else {
      _ordered = List.unmodifiable([
        taskId,
        ..._ordered.where((id) => id != taskId),
      ]);
      _ids = {..._ids, taskId};
    }
    _persist();
    notifyListeners();
    return _ids.contains(taskId);
  }

  /// Tira da relação sem alternar — usado quando a tarefa é excluída.
  void remove(String taskId) {
    if (!_ids.contains(taskId)) return;
    _ordered = List.unmodifiable(_ordered.where((id) => id != taskId));
    _ids = {..._ids}..remove(taskId);
    _persist();
    notifyListeners();
  }

  void _persist() {
    unawaited(repository.saveAll(_ordered));
  }
}
