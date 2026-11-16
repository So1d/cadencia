import 'package:cadencia/app/app_dependencies.dart';
import 'package:cadencia/app/cadencia_app.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/onboarding/data/onboarding_storage.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// O controlador de favoritos vive acima do `MaterialApp` no app de verdade:
/// aqui a árvore inteira sobe para garantir que listagem e detalhe o alcançam.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});
  });

  Future<void> startApp(WidgetTester tester) async {
    final dependencies = AppDependencies(
      taskRepository: FakeTaskRepository(
        seed: FakeTaskRepository.demo,
        latency: Duration.zero,
      ),
      eventRepository: FakeEventRepository(latency: Duration.zero),
      profileRepository: FakeProfileRepository(latency: Duration.zero),
      onboardingStorage: OnboardingStorage(),
      initialFavorites: const [FakeTaskRepository.demoFavoriteId],
    );

    await tester.pumpWidget(CadenciaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  testWidgets('modo demo abre com uma favorita e a estrela chega ao detalhe',
      (tester) async {
    await startApp(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.checklist_outlined),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Favoritas (1)'),
      findsOneWidget,
      reason: 'a semente do modo demo vem por AppDependencies.initialFavorites',
    );

    // A rota empilhada também enxerga o mesmo controlador.
    await tester.tap(find.text('Estudar Flutter por 30 minutos'));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Marcar Estudar Flutter por 30 minutos como favorita'),
      findsOneWidget,
    );

    await tester.tap(
      find.byTooltip('Marcar Estudar Flutter por 30 minutos como favorita'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Remover Estudar Flutter por 30 minutos dos favoritos'),
      findsOneWidget,
    );
  });
}
