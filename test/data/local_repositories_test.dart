import 'dart:convert';

import 'package:cadencia/features/events/data/local_event_repository.dart';
import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:cadencia/features/profile/data/local_profile_repository.dart';
import 'package:cadencia/features/profile/domain/entities/profile_focus.dart';
import 'package:cadencia/features/profile/domain/entities/user_profile.dart';
import 'package:cadencia/features/tasks/data/local_task_repository.dart';
import 'package:cadencia/features/tasks/domain/task.dart';
import 'package:cadencia/features/tasks/domain/task_priority.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync preferences;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    preferences = SharedPreferencesAsync();
  });

  group('LocalTaskRepository', () {
    test('começa vazio', () async {
      final repository = LocalTaskRepository(preferences: preferences);
      expect(await repository.fetchAll(), isEmpty);
    });

    test('salva e lê as tarefas', () async {
      final repository = LocalTaskRepository(preferences: preferences);
      final task = Task(
        title: 'Revisar',
        dueDate: DateTime(2026, 11, 10),
        priority: TaskPriority.high,
      );

      await repository.saveAll([task]);
      final loaded = await repository.fetchAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Revisar');
      expect(loaded.single.priority, TaskPriority.high);
      expect(loaded.single.dueDate, DateTime(2026, 11, 10));
    });

    test('lê o formato antigo (lista solta)', () async {
      final task = Task(id: 't1', title: 'Legado');
      await preferences.setString(
        'cadencia_tasks_v1',
        jsonEncode([task.toJson()]),
      );

      final repository = LocalTaskRepository(preferences: preferences);
      final loaded = await repository.fetchAll();

      expect(loaded.single.id, 't1');
      expect(loaded.single.title, 'Legado');
    });

    test('dado corrompido vira lista vazia', () async {
      await preferences.setString('cadencia_tasks_v1', 'isto não é json');

      final repository = LocalTaskRepository(preferences: preferences);
      expect(await repository.fetchAll(), isEmpty);
    });
  });

  group('LocalEventRepository', () {
    test('salva e lê os eventos', () async {
      final repository = LocalEventRepository(preferences: preferences);
      final event = CalendarEvent(
        title: 'Reunião',
        start: DateTime(2026, 11, 10, 9),
        end: DateTime(2026, 11, 10, 10),
      );

      await repository.saveAll([event]);
      final loaded = await repository.fetchAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Reunião');
      expect(loaded.single.end, DateTime(2026, 11, 10, 10));
    });

    test('dado corrompido vira lista vazia', () async {
      await preferences.setString('cadencia_events_v1', '{{{');

      final repository = LocalEventRepository(preferences: preferences);
      expect(await repository.fetchAll(), isEmpty);
    });
  });

  group('LocalProfileRepository', () {
    test('sem perfil salvo devolve o perfil vazio', () async {
      final repository = LocalProfileRepository(preferences: preferences);
      expect(await repository.load(), UserProfile.empty);
    });

    test('salva e lê o perfil', () async {
      final repository = LocalProfileRepository(preferences: preferences);
      const profile = UserProfile(
        name: 'Everton',
        focus: {ProfileFocus.deadlines},
        dailyGoal: 4,
        weekStartsMonday: false,
      );

      await repository.save(profile);

      expect(await repository.load(), profile);
    });

    test('dado corrompido vira perfil vazio', () async {
      await preferences.setString('cadencia_profile_v1', 'não é json');

      final repository = LocalProfileRepository(preferences: preferences);
      expect(await repository.load(), UserProfile.empty);
    });
  });
}
