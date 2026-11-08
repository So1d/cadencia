import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_helpers.dart';

/// Saudação + data de hoje. O nome vem do perfil (opcional).
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, this.name, this.now});

  final String? name;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final moment = now ?? DateTime.now();
    final text = Theme.of(context).textTheme;
    final greeting = greetingFor(moment);
    final title = name == null ? '$greeting!' : '$greeting, $name!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineSmall?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(moment),
          style: text.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
