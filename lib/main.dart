import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/cadencia_app.dart';

/// Ponto de partida do app.
///
/// Mantido intencionalmente curto: inicializa o que é global (símbolos de
/// data em português) e delega o resto para o [CadenciaApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const CadenciaApp());
}
