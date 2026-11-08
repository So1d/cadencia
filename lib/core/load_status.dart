/// Os quatro estados de uma tela que busca dados em um repositório.
///
/// Toda tela que carrega dados pode estar nestas situações — e tratar só uma
/// delas é o que faz apps "travarem em branco" quando algo dá errado.
enum LoadStatus {
  /// A busca ainda está em andamento.
  loading,

  /// A busca funcionou e há dados para mostrar.
  success,

  /// A busca funcionou, mas não há nenhum registro ainda (estado vazio).
  empty,

  /// A busca falhou (rede, disco, dado corrompido...).
  error,
}

extension LoadStatusX on LoadStatus {
  bool get isLoading => this == LoadStatus.loading;
  bool get isError => this == LoadStatus.error;
  bool get hasData => this == LoadStatus.success;
}
