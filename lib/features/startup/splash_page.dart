import 'package:flutter/material.dart';

import '../../core/storage/onboarding_storage.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';

/// Splash: ponto de decisão do fluxo inicial.
/// A plataforma mostra a Launch Screen nativa; o handoff acontece
/// no primeiro frame deste widget.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final OnboardingStorage _storage = OnboardingStorage();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final onboardingCompleted = await _storage.isCompleted();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => onboardingCompleted
            ? const HomePage()
            : const OnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'C',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'CADÊNCIA',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 4,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
