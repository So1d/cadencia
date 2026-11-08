import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/profile/presentation/profile_controller.dart';
import '../features/profile/presentation/profile_scope.dart';
import '../features/startup/presentation/splash_page.dart';
import '../state/schedule_controller.dart';
import '../state/schedule_scope.dart';
import 'app_dependencies.dart';
import 'theme/app_theme.dart';

/// Componente principal do Cadência.
///
/// Monta o `MaterialApp` (tema, idioma) e entrega a tela inicial. As
/// dependências entram por parâmetro — por isso os testes conseguem trocar o
/// armazenamento por dados falsos sem mexer no app.
class CadenciaApp extends StatefulWidget {
  const CadenciaApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<CadenciaApp> createState() => _CadenciaAppState();
}

class _CadenciaAppState extends State<CadenciaApp> {
  static const String _demo = String.fromEnvironment('CADENCIA_DEMO');

  late final AppDependencies _dependencies;
  late final ScheduleController _scheduleController;
  late final ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ??
        (_demo.isEmpty
            ? AppDependencies.production()
            : AppDependencies.demo(_demo));

    _scheduleController = ScheduleController(
      taskRepository: _dependencies.taskRepository,
      eventRepository: _dependencies.eventRepository,
    );
    _profileController = ProfileController(_dependencies.profileRepository);
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Acima do MaterialApp: as rotas empilhadas também enxergam os escopos.
    return ScheduleScope(
      controller: _scheduleController,
      child: ProfileScope(
        controller: _profileController,
        child: MaterialApp(
          title: 'Cadência',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SplashPage(
            onboardingStorage: _dependencies.onboardingStorage,
          ),
        ),
      ),
    );
  }
}
