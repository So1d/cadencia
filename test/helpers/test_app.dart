import 'package:cadencia/app/theme/app_theme.dart';
import 'package:cadencia/features/favorites/data/fake_favorites_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/profile/presentation/profile_scope.dart';
import 'package:cadencia/state/schedule_controller.dart';
import 'package:cadencia/state/schedule_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// Controlador de favoritos pronto para teste, com relação inicial opcional.
FavoritesController buildFavorites({List<String> seed = const []}) {
  return FavoritesController(
    repository: FakeFavoritesRepository(
      seed: seed,
      latency: Duration.zero,
    ),
  );
}

/// Monta a árvore mínima usada pelos testes de widget: escopos + MaterialApp.
///
/// O `schedule` é opcional para telas que só dependem do perfil. O
/// `favorites` é criado vazio quando o teste não precisa inspecioná-lo.
Widget wrapWithScopes({
  ScheduleController? schedule,
  FavoritesController? favorites,
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

  app = ChangeNotifierProvider<FavoritesController>.value(
    value: favorites ?? buildFavorites(),
    child: app,
  );

  return ProfileScope(controller: profile, child: app);
}
