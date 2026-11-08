import 'package:flutter/foundation.dart';

import '../domain/entities/user_profile.dart';
import '../domain/repositories/profile_repository.dart';

/// Dono do perfil: carrega, salva e avisa quem depende dele.
class ProfileController extends ChangeNotifier {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  UserProfile _profile = UserProfile.empty;
  bool _isLoaded = false;
  Future<void>? _loading;

  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  /// Carrega uma única vez, mesmo que duas telas chamem ao mesmo tempo.
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      _profile = await _repository.load();
    } catch (error) {
      // O perfil melhora o app, mas não pode impedir que ele abra.
      debugPrint('Não foi possível carregar o perfil: $error');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(UserProfile profile) async {
    await _repository.save(profile);
    _profile = profile;
    _isLoaded = true;
    notifyListeners();
  }
}
