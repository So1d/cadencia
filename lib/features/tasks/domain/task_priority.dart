/// Prioridade de uma tarefa — enum aprimorado, com valor persistido e rótulo.
///
/// O domínio é Dart puro (sem Flutter): ele não precisa saber de ícones nem de
/// cores. A aparência fica na camada de apresentação.
enum TaskPriority {
  low(0, 'Baixa'),
  medium(1, 'Média'),
  high(2, 'Alta');

  const TaskPriority(this.value, this.label);

  /// Valor gravado em JSON. Mantido como int para os dados salvos por
  /// versões antigas do app continuarem legíveis.
  final int value;

  /// Texto pronto para exibir (0 == 'Baixa', sem repetir `switch` na UI).
  final String label;

  /// Recupera a prioridade a partir do valor persistido.
  ///
  /// Se chegar um número desconhecido (arquivo antigo ou editado à mão),
  /// devolve `medium` em vez de quebrar o app.
  static TaskPriority fromValue(int value) => TaskPriority.values.firstWhere(
        (p) => p.value == value,
        orElse: () => TaskPriority.medium,
      );
}
