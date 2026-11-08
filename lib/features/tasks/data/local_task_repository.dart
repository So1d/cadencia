import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/task_repository.dart';
import '../domain/task.dart';

/// Persiste as tarefas no aparelho, via `shared_preferences`.
///
/// É a implementação "de verdade": offline-first, sem servidor.
class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _key = 'cadencia_tasks_v1';
  static const int _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Task>> fetchAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      // Aceita o envelope atual ({"items": [...]}) e o formato antigo
      // (lista solta), para não perder dados de versões anteriores.
      final items = decoded is Map ? decoded['items'] : decoded;
      if (items is! List<Object?>) return const [];
      return [
        for (final item in items)
          if (item is Map)
            Task.fromJson(Map<String, Object?>.from(item)),
      ];
    } on FormatException {
      // Dado corrompido não pode travar o app para sempre: partimos do vazio.
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    final payload = {
      'schema_version': _schemaVersion,
      'items': [for (final task in tasks) task.toJson()],
    };
    await _preferences.setString(_key, jsonEncode(payload));
  }
}
