import 'package:flutter/material.dart';

import '../features/startup/splash_page.dart';
import '../core/theme/app_theme.dart';

class CadenciaApp extends StatelessWidget {
  const CadenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadência',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashPage(),
    );
  }
}
