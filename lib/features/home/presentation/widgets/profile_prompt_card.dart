import 'package:flutter/material.dart';

import '../../../../app/common/widgets/status_message.dart';

/// Convite para preencher o perfil. Some quando o perfil fica completo.
class ProfilePromptCard extends StatelessWidget {
  const ProfilePromptCard({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return StatusMessage(
      icon: Icons.tune,
      message: 'Diga o que você quer priorizar e o Cadência ajusta a Home '
          'para o seu ritmo.',
      actionLabel: 'Completar perfil',
      onAction: onComplete,
    );
  }
}
