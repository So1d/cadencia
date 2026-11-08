import '../domain/entities/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

/// Perfil em memória — ideal para testes e para o modo demonstração.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    UserProfile initial = UserProfile.empty,
    this.latency = Duration.zero,
    this.shouldFail = false,
  }) : _profile = initial;

  UserProfile _profile;
  final Duration latency;
  final bool shouldFail;

  @override
  Future<UserProfile> load() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (shouldFail) {
      throw Exception('Falha simulada ao carregar o perfil.');
    }
    return _profile;
  }

  @override
  Future<void> save(UserProfile profile) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (shouldFail) {
      throw Exception('Falha simulada ao salvar o perfil.');
    }
    _profile = profile;
  }
}
