import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Home provisória: destino final do primeiro fluxo.
/// Calendário e tarefas entram aqui depois.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text(
          'Cadência',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOME PROVISÓRIA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      letterSpacing: 2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aqui entram o calendário e as tarefas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
