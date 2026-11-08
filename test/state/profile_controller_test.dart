import 'package:cadencia/features/profile/data/fake_profile_repository.dart';
import 'package:cadencia/features/profile/domain/entities/profile_focus.dart';
import 'package:cadencia/features/profile/domain/entities/user_profile.dart';
import 'package:cadencia/features/profile/domain/repositories/profile_repository.dart';
import 'package:cadencia/features/profile/presentation/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrega o perfil do repositório', () async {
    final controller = ProfileController(
      FakeProfileRepository(
        initial: const UserProfile(
          name: 'Ana',
          focus: {ProfileFocus.events},
        ),
        latency: Duration.zero,
      ),
    );

    expect(controller.isLoaded, isFalse);
    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.profile.name, 'Ana');
    expect(controller.profile.focus, {ProfileFocus.events});
    controller.dispose();
  });

  test('falha ao carregar não impede o app de abrir', () async {
    final controller = ProfileController(
      FakeProfileRepository(shouldFail: true, latency: Duration.zero),
    );

    await controller.load();

    expect(controller.isLoaded, isTrue);
    expect(controller.profile, UserProfile.empty);
    controller.dispose();
  });

  test('salvar atualiza o perfil em memória', () async {
    final repository = FakeProfileRepository(latency: Duration.zero);
    final controller = ProfileController(repository);
    await controller.load();

    const updated = UserProfile(
      name: 'Bia',
      focus: {ProfileFocus.deadlines},
      dailyGoal: 5,
    );
    await controller.save(updated);

    expect(controller.profile, updated);
    expect(await repository.load(), updated);
    controller.dispose();
  });

  test('load é idempotente: o repositório é chamado uma vez', () async {
    var calls = 0;
    final repository = _CountingRepository(() => calls++);
    final controller = ProfileController(repository);

    await Future.wait([controller.load(), controller.load()]);

    expect(calls, 1);
    controller.dispose();
  });
}

class _CountingRepository implements ProfileRepository {
  _CountingRepository(this.onLoad);

  final void Function() onLoad;

  @override
  Future<UserProfile> load() async {
    onLoad();
    return UserProfile.empty;
  }

  @override
  Future<void> save(UserProfile profile) async {}
}
