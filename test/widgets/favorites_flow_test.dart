import 'package:cadencia/app/app_dependencies.dart';
import 'package:cadencia/app/cadencia_app.dart';
import 'package:cadencia/features/events/data/fake_event_repository.dart';
import 'package:cadencia/features/favorites/data/fake_favorites_repository.dart';
import 'package:cadencia/features/favorites/data/local_favorites_repository.dart';
import 'package:cadencia/features/onboarding/data/onboarding_storage.dart';
import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/tasks/data/fake_task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // A tela de Tarefas agora tem busca, chips e barra: em 800x600 a lista
  // começa abaixo da dobra e o `SliverList` só monta o que aparece.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> startApp(
    WidgetTester tester, {
    FakeFavoritesRepository? favorites,
  }) async {
    final dependencies = AppDependencies(
      taskRepository: FakeTaskRepository(
        seed: FakeTaskRepository.demo,
        latency: Duration.zero,
      ),
      eventRepository: FakeEventRepository(latency: Duration.zero),
      profileRepository: FakeProfileRepository(latency: Duration.zero),
      onboardingStorage: OnboardingStorage(),
      favoritesRepository: favorites ??
          FakeFavoritesRepository(
            seed: const [FakeTaskRepository.demoFavoriteId],
            latency: Duration.zero,
          ),
    );

    await tester.pumpWidget(CadenciaApp(dependencies: dependencies));
    await tester.pumpAndSettle();
  }

  testWidgets('modo demo abre com uma favorita e a estrela chega ao detalhe',
      (tester) async {
    useTallScreen(tester);
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
      reason: 'a semente do modo demo vem do repositório falso de favoritos',
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

  testWidgets('favorito sobrevive a fechar e abrir o app', (tester) async {
    useTallScreen(tester);
    final preferences = SharedPreferencesAsync();

    Future<void> openApp() async {
      final dependencies = AppDependencies(
        taskRepository: FakeTaskRepository(
          seed: FakeTaskRepository.demo,
          latency: Duration.zero,
        ),
        eventRepository: FakeEventRepository(latency: Duration.zero),
        profileRepository: FakeProfileRepository(latency: Duration.zero),
        favoritesRepository: LocalFavoritesRepository(
          preferences: preferences,
        ),
        onboardingStorage: OnboardingStorage(preferences: preferences),
      );
      await tester.pumpWidget(CadenciaApp(dependencies: dependencies));
      await tester.pumpAndSettle();
    }

    Future<void> openTasksTab() async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.checklist_outlined),
        ),
      );
      await tester.pumpAndSettle();
    }

    await openApp();
    await openTasksTab();

    expect(find.text('Favoritas (0)'), findsOneWidget);

    await tester.tap(
      find.byTooltip('Marcar Estudar Flutter por 30 minutos como favorita'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favoritas (1)'), findsOneWidget);

    // "Fecha" o app: a árvore inteira sai do ar e o disco fica com a relação.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await openApp();
    await openTasksTab();

    expect(find.text('Favoritas (1)'), findsOneWidget);
    expect(
      find.byTooltip('Remover Estudar Flutter por 30 minutos dos favoritos'),
      findsOneWidget,
      reason: 'a relação de ids é gravada no aparelho a cada mudança',
    );
  });

  testWidgets('falha ao gravar o favorito avisa e desfaz a estrela',
      (tester) async {
    useTallScreen(tester);
    await startApp(
      tester,
      favorites: FakeFavoritesRepository(
        latency: Duration.zero,
        shouldFailSave: true,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.checklist_outlined),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byTooltip('Marcar Estudar Flutter por 30 minutos como favorita'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível salvar o favorito. Tente de novo.'),
      findsOneWidget,
      reason: 'a gravação falhou e ninguém pode ficar sem saber',
    );
    expect(
      find.byTooltip('Marcar Estudar Flutter por 30 minutos como favorita'),
      findsOneWidget,
      reason: 'a estrela volta: marca que não persiste é mentira',
    );
    expect(find.text('Favoritas (0)'), findsOneWidget);
  });
}
