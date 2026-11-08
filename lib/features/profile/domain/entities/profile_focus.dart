/// O que a pessoa quer ver primeiro na Home.
///
/// Enum aprimorado: o valor é persistido, o rótulo é exibido e a descrição
/// explica a consequência da escolha — sem espalhar textos pela UI.
enum ProfileFocus {
  deadlines(
    0,
    'Prazos',
    'Tarefas que vencem hoje aparecem no topo.',
  ),
  events(
    1,
    'Agenda',
    'Compromissos do dia aparecem antes das tarefas.',
  ),
  balance(
    2,
    'Equilíbrio',
    'Resumo do dia sem priorizar uma seção.',
  );

  const ProfileFocus(this.value, this.label, this.description);

  /// Valor gravado em JSON.
  final int value;

  /// Texto exibido na tela.
  final String label;

  /// Frase curta que explica o efeito da escolha.
  final String description;

  static ProfileFocus fromValue(int value) =>
      tryFromValue(value) ?? ProfileFocus.balance;

  /// Devolve `null` para valor desconhecido — útil ao ler JSON antigo, em que
  /// o melhor é ignorar o item e não inventar uma preferência.
  static ProfileFocus? tryFromValue(int value) {
    for (final focus in ProfileFocus.values) {
      if (focus.value == value) return focus;
    }
    return null;
  }
}
