import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/domain/entities/profile_focus.dart';
import 'package:cadencia/features/profile/domain/entities/user_profile.dart';
import 'package:cadencia/features/profile/presentation/pages/profile_form_page.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:cadencia/features/profile/presentation/profile_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  Future<ProfileController> controller({
    UserProfile initial = UserProfile.empty,
  }) async {
    final controller = ProfileController(
      FakeProfileRepository(initial: initial, latency: Duration.zero),
    );
    await controller.load();
    return controller;
  }

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('valida prioridade obrigatória', (tester) async {
    useTallScreen(tester);
    final profile = await controller();

    await tester.pumpWidget(
      wrapWithScopes(
        profile: profile,
        home: const ProfileFormPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ana');
    await tester.pump();

    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Escolha pelo menos uma prioridade.'), findsOneWidget);
    expect(profile.profile.name, isNull);

    profile.dispose();
  });

  testWidgets('salva nome, prioridade, meta e início da semana',
      (tester) async {
    useTallScreen(tester);
    final profile = await controller();

    await tester.pumpWidget(
      wrapWithScopes(
        profile: profile,
        home: const ProfileFormPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name')), '  Ana  ');
    await tester.tap(find.text('Prazos'));
    await tester.pump();

    await tester.tap(find.text('Semana começa na segunda'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(profile.profile.name, 'Ana');
    expect(profile.profile.focus, {ProfileFocus.deadlines});
    expect(profile.profile.weekStartsMonday, isFalse);

    profile.dispose();
  });

  testWidgets('perfil já completo é carregado no formulário', (tester) async {
    useTallScreen(tester);
    final profile = await controller(
      initial: const UserProfile(
        name: 'Bia',
        focus: {ProfileFocus.events},
        dailyGoal: 5,
      ),
    );

    await tester.pumpWidget(
      wrapWithScopes(
        profile: profile,
        home: const ProfileFormPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Sem mudanças, o botão fica desabilitado.
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('profile-save')),
    );
    expect(button.onPressed, isNull);

    profile.dispose();
  });

  testWidgets('salvar em rota empilhada volta sem pedir descarte',
      (tester) async {
    useTallScreen(tester);
    final profile = await controller();

    await tester.pumpWidget(
      ProfileScope(
        controller: profile,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(ProfileFormPage.route()),
                  child: const Text('Abrir perfil'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ana');
    await tester.tap(find.text('Prazos'));
    await tester.pump();

    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsNothing);
    expect(find.text('Abrir perfil'), findsOneWidget);
    expect(profile.profile.name, 'Ana');
    expect(profile.profile.focus, {ProfileFocus.deadlines});

    profile.dispose();
  });

  testWidgets('voltar com mudanças pede confirmação', (tester) async {
    useTallScreen(tester);
    final profile = await controller();

    await tester.pumpWidget(
      ProfileScope(
        controller: profile,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(ProfileFormPage.route()),
                  child: const Text('Abrir perfil'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir perfil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name')), 'Ana');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir perfil'), findsOneWidget);
    expect(profile.profile.name, isNull);
    expect(profile.profile, UserProfile.empty);

    profile.dispose();
  });
}
