import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/task_priority.dart';

/// Aparência de cada nível de prioridade.
///
/// Fica na apresentação **de propósito**: o enum do domínio é Dart puro, sem
/// dependência de Flutter. Quem precisa de ícone ou cor estende o enum aqui.
extension TaskPriorityView on TaskPriority {
  IconData get icon => switch (this) {
        TaskPriority.high => Icons.flag,
        TaskPriority.medium => Icons.flag_outlined,
        TaskPriority.low => Icons.outlined_flag,
      };

  Color get color => switch (this) {
        TaskPriority.high => AppColors.danger,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.low => AppColors.primary,
      };

  Color get background => color.withValues(alpha: 0.12);
}
