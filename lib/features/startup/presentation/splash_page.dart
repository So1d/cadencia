import 'package:flutter/material.dart';

import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../features/onboarding/data/onboarding_storage.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/profile/presentation/profile_scope.dart';
import '../../../state/schedule_scope.dart';

/// Splash: ponto de decisão do fluxo inicial.
///
/// Enquanto a marca aparece, o app carrega agenda e perfil. Só depois decide
/// se mostra o onboarding (primeira execução) ou a shell principal.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onboardingStorage});

  final OnboardingStorage onboardingStorage;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Espera o primeiro quadro: carregar dados e navegar dentro do build
    // derrubaria o app ("setState during build").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final schedule = ScheduleScope.read(context);
    final profile = ProfileScope.read(context);

    // Tempo mínimo de marca: evita um "pisca" quando o disco responde rápido.
    final minimum = Future<void>.delayed(const Duration(milliseconds: 900));

    await Future.wait([
      schedule.init(),
      profile.load(),
      minimum,
    ]);

    final onboardingCompleted =
        await widget.onboardingStorage.isCompleted();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => onboardingCompleted
            ? const AppShell()
            : OnboardingPage(onboardingStorage: widget.onboardingStorage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'C',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'CADÊNCIA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 6,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Carregando o Cadência',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
