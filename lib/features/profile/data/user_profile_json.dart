import '../domain/entities/profile_focus.dart';
import '../domain/entities/user_profile.dart';

// Chaves em snake_case: os mesmos nomes serviriam de colunas num banco.
extension UserProfileJson on UserProfile {
  Map<String, Object?> toJson() => {
        'name': name,
        'focus': [for (final item in focus) item.value],
        'daily_goal': dailyGoal,
        'week_starts_monday': weekStartsMonday,
      };
}

/// Converte JSON em [UserProfile] sem confiar cegamente no arquivo.
///
/// Campo desconhecido ou inválido é ignorado; o app abre com o padrão em vez
/// de quebrar por causa de um dado velho.
UserProfile userProfileFromJson(Map<String, Object?> json) {
  final rawFocus = json['focus'];
  final focus = <ProfileFocus>{
    if (rawFocus is List<Object?>)
      for (final value in rawFocus)
        if (value is int) ?ProfileFocus.tryFromValue(value),
  };

  final rawName = json['name'];
  final name = rawName is String && rawName.trim().isNotEmpty
      ? rawName.trim()
      : null;

  final rawGoal = json['daily_goal'];
  final goal = rawGoal is int ? rawGoal.clamp(1, 10) : 3;

  return UserProfile(
    name: name,
    focus: focus,
    dailyGoal: goal,
    weekStartsMonday: json['week_starts_monday'] != false,
  );
}
