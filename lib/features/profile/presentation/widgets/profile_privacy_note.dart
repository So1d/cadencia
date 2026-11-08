import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// Aviso de privacidade: explica onde os dados ficam antes de salvar.
class ProfilePrivacyNote extends StatelessWidget {
  const ProfilePrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 18, color: scheme.outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Suas preferências ficam só neste aparelho. O Cadência não envia '
            'seus dados para nenhum servidor.',
            style: text.bodySmall?.copyWith(color: scheme.outline),
          ),
        ),
      ],
    );
  }
}
