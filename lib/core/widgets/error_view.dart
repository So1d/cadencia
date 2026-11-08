import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Estado **erro**: explica o que houve em português simples e oferece saída.
///
/// Regra do material do curso: nunca deixar a tela em branco nem jogar um
/// stack trace na cara de quem está usando.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Não foi possível carregar',
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Erro ao carregar os dados',
              child: Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: scheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: text.bodyMedium?.copyWith(color: scheme.outline),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
