import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../onboarding_item.dart';

class OnboardingContent extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
