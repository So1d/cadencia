import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../tasks/domain/task.dart';
import 'favorites_controller.dart';

/// Alterna a estrela e avisa quando a gravação falha.
///
/// A estrela aparece em três telas (Home, Tarefas e detalhe) e cada uma
/// chamava `toggle` direto: uma falha de disco morria em silêncio, a marca
/// sumia no próximo boot e ninguém entendia por quê. Um só lugar para o toque
/// e para o aviso.
Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  Task task,
) async {
  final favorites = context.read<FavoritesController>();
  // Capturado antes do await: tocar no context depois dele é exatamente o que
  // o analisador barra em `use_build_context_synchronously`.
  final messenger = ScaffoldMessenger.of(context);

  try {
    await favorites.toggle(task.id);
  } catch (_) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o favorito. Tente de novo.'),
        ),
      );
  }
}
