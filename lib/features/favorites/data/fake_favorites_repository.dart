import '../domain/repositories/favorites_repository.dart';

/// Repositório **falso** de favoritos, com atraso simulado.
///
/// Serve ao modo demonstração (semente pronta) e aos testes, que precisam
/// inspecionar o que foi gravado sem tocar no armazenamento do aparelho.
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({
    List<String>? seed,
    this.latency = const Duration(milliseconds: 200),
    this.shouldFail = false,
  }) : _saved = [...?seed];

  /// Tempo simulado de leitura/gravação.
  final Duration latency;

  /// Quando verdadeiro, [fetchAll] lança exceção.
  final bool shouldFail;

  List<String> _saved;

  /// Última relação gravada — é o que os testes conferem.
  List<String> get saved => List.unmodifiable(_saved);

  @override
  Future<List<String>> fetchAll() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (shouldFail) {
      throw Exception('Falha simulada ao carregar os favoritos.');
    }
    return List.unmodifiable(_saved);
  }

  @override
  Future<void> saveAll(List<String> taskIds) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _saved = [...taskIds];
  }
}
