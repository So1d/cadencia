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

  /// Última gravação agendada. Serve de fila: sem ela, dois toques rápidos
  /// chegariam ao disco fora de ordem e a relação salva poderia não ser a que
  /// a tela mostra.
  Future<void> _fila = Future<void>.value();

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
  /// A mudança aparece na hora e a gravação vem em seguida. Se ela falhar, o
  /// estado volta ao anterior e o erro é relançado: uma estrela acesa que não
  /// sobrevive ao próximo boot é pior do que um aviso na hora. Quem chama
  /// decide o que mostrar — ver `toggleFavoriteWithFeedback`.
  Future<bool> toggle(String taskId) async {
    final anteriorOrdered = _ordered;
    final anteriorIds = _ids;

    if (_ids.contains(taskId)) {
      _ordered = List.unmodifiable(_ordered.where((id) => id != taskId));
      _ids = {..._ids}..remove(taskId);
    } else {
      _ordered = List.unmodifiable([
        taskId,
        ..._ordered.where((id) => id != taskId),
      ]);
      _ids = {..._ids, taskId};
    }
    final aplicado = _ordered;
    notifyListeners();

    try {
      await _gravar(aplicado);
    } catch (_) {
      // Só desfaz se ninguém mexeu depois: com toques em sequência o estado
      // atual já é outro, e voltar ao anterior apagaria a escolha mais nova.
      if (identical(_ordered, aplicado)) {
        _ordered = anteriorOrdered;
        _ids = anteriorIds;
        notifyListeners();
      }
      rethrow;
    }

    return _ids.contains(taskId);
  }

  /// Tira da relação sem alternar — usado quando a tarefa é excluída.
  ///
  /// Aqui não há retorno para a tela: a exclusão já removeu a tarefa, e uma
  /// gravação que falha só faz o id voltar na próxima abertura, sem afetar a
  /// lista visível.
  void remove(String taskId) {
    if (!_ids.contains(taskId)) return;
    _ordered = List.unmodifiable(_ordered.where((id) => id != taskId));
    _ids = {..._ids}..remove(taskId);
    unawaited(_gravar(_ordered).catchError((Object _) {}));
    notifyListeners();
  }

  Future<void> _gravar(List<String> snapshot) {
    final gravacao = _fila.then((_) => repository.saveAll(snapshot));
    // A fila não pode morrer por causa de uma falha: quem espera recebe o erro
    // pela future devolvida, mas o próximo agendamento depende da versão
    // tratada.
    _fila = gravacao.then((_) {}, onError: (Object _) {});
    return gravacao;
  }
}
