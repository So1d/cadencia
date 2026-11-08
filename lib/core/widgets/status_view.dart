import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../load_status.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// Renderiza um dos **4 estados** de uma tela orientada a dados.
///
/// Recebe o estado vindo do repositório ([status]) e se a coleção está vazia
/// ([isEmpty]) e devolve a visão certa. Centralizar essa decisão aqui evita
/// que cada tela reinvente (e esqueça) algum dos estados.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    required this.isEmpty,
    required this.child,
    required this.onRetry,
    this.errorMessage = 'Não foi possível carregar seus dados.',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage = 'Nada por aqui ainda.',
    this.emptyAction,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  /// Estado vindo do repositório (loading, error ou success).
  final LoadStatus status;

  /// Se a coleção correspondente está vazia.
  final bool isEmpty;

  /// Conteúdo exibido quando há dados.
  final Widget child;

  /// Recarrega os dados ([LoadStatus.error] e tentativas de novo).
  final VoidCallback? onRetry;

  final String errorMessage;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget? emptyAction;

  /// Respiro aplicado apenas aos estados de carregando/erro/vazio.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Combinando o estado da carga com o fato de haver (ou não) registros,
    // chegamos ao estado efetivo: um dos quatro.
    final effective = switch (status) {
      LoadStatus.loading || LoadStatus.error => status,
      _ => isEmpty ? LoadStatus.empty : LoadStatus.success,
    };

    return switch (effective) {
      LoadStatus.loading => Padding(
          padding: padding,
          child: const LoadingView(message: 'Carregando sua cadência...'),
        ),
      LoadStatus.error => Padding(
          padding: padding,
          child: ErrorView(message: errorMessage, onRetry: onRetry),
        ),
      LoadStatus.empty => Padding(
          padding: padding,
          child: EmptyView(
            icon: emptyIcon,
            message: emptyMessage,
            action: emptyAction,
          ),
        ),
      LoadStatus.success => child,
    };
  }
}

/// Recuo padrão para listas dentro das páginas.
const EdgeInsets kListPadding = EdgeInsets.fromLTRB(
  AppSpacing.md,
  AppSpacing.sm,
  AppSpacing.md,
  AppSpacing.xxl,
);
