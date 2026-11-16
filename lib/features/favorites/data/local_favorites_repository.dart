import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/favorites_repository.dart';

/// Persiste a relação de favoritos no aparelho, via `shared_preferences`.
///
/// Guarda só a lista ordenada de ids: a tarefa em si continua no repositório
/// de tarefas, e a ordem salva é a própria ordem de escolha (mais recente
/// primeiro), então sobrevive a fechar o app.
class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'cadencia_favorites_v1';
  static const int _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> fetchAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      // Aceita o envelope atual e uma lista solta (formato futuro/legado).
      final items = decoded is Map ? decoded['items'] : decoded;
      if (items is! List<Object?>) return const [];
      return [
        for (final item in items)
          if (item is String && item.isNotEmpty) item,
      ];
    } on FormatException {
      // Dado corrompido não pode travar o app: começa sem favoritos.
      return const [];
    }
  }

  @override
  Future<void> saveAll(List<String> taskIds) async {
    final payload = {
      'schema_version': _schemaVersion,
      'items': taskIds,
    };
    await _preferences.setString(_key, jsonEncode(payload));
  }
}
