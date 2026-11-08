import 'package:shared_preferences/shared_preferences.dart';

import '../features/events/data/fake_event_repository.dart';
import '../features/events/data/local_event_repository.dart';
import '../features/events/domain/repositories/event_repository.dart';
import '../features/onboarding/data/onboarding_storage.dart';
import '../features/profile/data/local_profile_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/tasks/data/fake_task_repository.dart';
import '../features/tasks/data/local_task_repository.dart';
import '../features/tasks/domain/repositories/task_repository.dart';

/// Monta as dependências do app num lugar só.
///
/// A tela não escolhe se os dados vêm do aparelho ou de um repositório falso:
/// essa decisão acontece aqui, na borda do sistema.
class AppDependencies {
  const AppDependencies({
    required this.taskRepository,
    required this.eventRepository,
    required this.profileRepository,
    required this.onboardingStorage,
  });

  final TaskRepository taskRepository;
  final EventRepository eventRepository;
  final ProfileRepository profileRepository;
  final OnboardingStorage onboardingStorage;

  /// App de verdade: tudo persistido no aparelho.
  factory AppDependencies.production() {
    final preferences = SharedPreferencesAsync();
    return AppDependencies(
      taskRepository: LocalTaskRepository(preferences: preferences),
      eventRepository: LocalEventRepository(preferences: preferences),
      profileRepository: LocalProfileRepository(preferences: preferences),
      onboardingStorage: OnboardingStorage(preferences: preferences),
    );
  }

  /// Modo demonstração dos quatro estados:
  ///
  ///     flutter run --dart-define=CADENCIA_DEMO=slow
  ///     flutter run --dart-define=CADENCIA_DEMO=error
  ///
  /// `error` falha uma única vez: o erro aparece na abertura e o
  /// "Tentar novamente" realmente recupera.
  factory AppDependencies.demo(String mode) {
    final latency = Duration(seconds: mode == 'slow' ? 5 : 1);
    return AppDependencies(
      taskRepository: FakeTaskRepository(
        seed: FakeTaskRepository.demo,
        latency: latency,
        failuresRemaining: mode == 'error' ? 1 : 0,
      ),
      eventRepository: FakeEventRepository(
        seed: FakeEventRepository.demo,
        latency: latency,
      ),
      profileRepository: LocalProfileRepository(),
      onboardingStorage: OnboardingStorage(),
    );
  }
}
