import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Botão de estrela do favorito.
///
/// Componente puramente apresentacional: não conhece o controlador nem sabe
/// salvar nada, só desenha o estado que recebeu e avisa quem o montou. É usado
/// na linha da tarefa, no detalhe da tarefa e no formulário.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.taskTitle,
    required this.isFavorite,
    required this.onPressed,
    this.compact = false,
  });

  /// Nome da tarefa entra no rótulo: numa lista com várias estrelas, o leitor
  /// de tela precisa saber **de qual** tarefa se trata.
  final String taskTitle;

  final bool isFavorite;
  final VoidCallback onPressed;

  /// Versão miúda para a linha da lista (o detalhe e o diálogo usam o padrão).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isFavorite
          ? 'Remover $taskTitle dos favoritos'
          : 'Marcar $taskTitle como favorita',
      onPressed: onPressed,
      iconSize: compact ? 18 : 24,
      visualDensity: compact ? VisualDensity.compact : null,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact
          ? const BoxConstraints(minWidth: 36, minHeight: 36)
          : null,
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? AppColors.warning : AppColors.textMuted,
      ),
    );
  }
}
