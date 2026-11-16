/// Contrato de persistência dos favoritos.
///
/// O favorito é uma relação de ids (ordem de escolha + pertinência), não um
/// campo da tarefa: por isso o contrato fala só de `String`.
abstract interface class FavoritesRepository {
  /// Ids favoritados, do mais recente para o mais antigo.
  Future<List<String>> fetchAll();

  /// Grava a relação inteira, na ordem recebida.
  Future<void> saveAll(List<String> taskIds);
}
