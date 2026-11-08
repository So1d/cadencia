import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/profile_focus.dart';
import '../../domain/entities/user_profile.dart';

/// Resumo do perfil salvo, com atalho para editar.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = profile.name;
    final secondary = text.bodyMedium?.copyWith(color: scheme.outline);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryHover,
                    foregroundColor: AppColors.textLight,
                    child: name == null
                        ? const Icon(Icons.person_outline)
                        : Text(
                            name.characters.first.toUpperCase(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      name ?? 'Seu perfil',
                      style: text.titleLarge?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Você quer ver primeiro', style: secondary),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final focus in ProfileFocus.values)
                  if (profile.focus.contains(focus))
                    Chip(
                      label: Text(focus.label),
                      avatar: const Icon(Icons.bolt, size: 16),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Meta diária: ${profile.dailyGoal} '
                  'tarefa${profile.dailyGoal == 1 ? '' : 's'}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              icon: Icons.calendar_view_week_outlined,
              label: 'Semana começa na '
                  '${profile.weekStartsMonday ? 'segunda' : 'domingo'}',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label)),
      ],
    );
  }
}
