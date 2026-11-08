import 'package:flutter/material.dart';

import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/loading_view.dart';
import '../profile_scope.dart';
import '../widgets/profile_privacy_note.dart';
import '../widgets/profile_summary_card.dart';
import 'profile_form_page.dart';

/// Aba "Perfil": mostra o que está salvo e leva ao formulário.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _openForm(BuildContext context) {
    Navigator.of(context).push(ProfileFormPage.route());
  }

  @override
  Widget build(BuildContext context) {
    // of: a aba é reconstruída sempre que o perfil muda.
    final controller = ProfileScope.of(context);
    final profile = controller.profile;
    final horizontal = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: !controller.isLoaded
          ? const LoadingView(message: 'Carregando seu perfil...')
          : ListView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.md,
                horizontal,
                AppSpacing.xl,
              ),
              children: [
                if (profile.isComplete)
                  ProfileSummaryCard(
                    profile: profile,
                    onEdit: () => _openForm(context),
                  )
                else
                  StatusMessage(
                    icon: Icons.tune,
                    message: 'Conte o que você quer priorizar para '
                        'personalizar o Cadência.',
                    actionLabel: 'Completar perfil',
                    onAction: () => _openForm(context),
                  ),
                const SizedBox(height: AppSpacing.lg),
                const _HowItWorksCard(),
                const SizedBox(height: AppSpacing.lg),
                const ProfilePrivacyNote(),
              ],
            ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMO O PERFIL MUDA O APP',
              style: text.labelSmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _Bullet(
              icon: Icons.waving_hand_outlined,
              text: 'O nome aparece na saudação da Home.',
            ),
            const _Bullet(
              icon: Icons.reorder,
              text: 'A prioridade escolhida define a ordem das seções.',
            ),
            const _Bullet(
              icon: Icons.flag_outlined,
              text: 'A meta diária aparece no cartão de progresso.',
            ),
            const _Bullet(
              icon: Icons.calendar_view_week_outlined,
              text: 'O início da semana muda o calendário.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
