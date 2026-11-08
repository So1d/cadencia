import 'package:cadencia/app/theme/app_theme.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/profile/presentation/profile_scope.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:cadencia/state/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Monta a árvore mínima usada pelos testes de widget: escopos + MaterialApp.
///
/// O `schedule` é opcional para telas que só dependem do perfil.
Widget wrapWithScopes({
  ScheduleController? schedule,
  required ProfileController profile,
  required Widget home,
}) {
  Widget app = MaterialApp(
    theme: AppTheme.dark,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  );

  if (schedule != null) {
    app = ScheduleScope(controller: schedule, child: app);
  }

  return ProfileScope(controller: profile, child: app);
}
