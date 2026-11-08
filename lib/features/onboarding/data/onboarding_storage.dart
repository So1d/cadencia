import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local do estado do onboarding.
/// Dado em chave/valor — não precisa de SQL nem nuvem.
class OnboardingStorage {
  static const String _completedKey = 'onboardingCompleted';

  final SharedPreferencesAsync _preferences;

  OnboardingStorage({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  Future<bool> isCompleted() async =>
      await _preferences.getBool(_completedKey) ?? false;

  Future<void> markAsCompleted() async =>
      await _preferences.setBool(_completedKey, true);

  /// Usado nos testes para simular "primeira execução".
  Future<void> reset() async => _preferences.remove(_completedKey);
}
