import 'profile_focus.dart';

/// Preferências que personalizam a Home do Cadência.
///
/// Imutável e comparável por valor: o formulário consegue saber exatamente
/// quando o rascunho mudou em relação ao perfil salvo.
class UserProfile {
  const UserProfile({
    this.name,
    this.focus = const {},
    this.dailyGoal = 3,
    this.weekStartsMonday = true,
  });

  /// Perfil inicial: nada preenchido.
  static const UserProfile empty = UserProfile();

  final String? name;

  /// O que a pessoa quer ver primeiro. Vazio = perfil incompleto.
  final Set<ProfileFocus> focus;

  /// Quantas tarefas a pessoa quer concluir por dia (1 a 10).
  final int dailyGoal;

  /// Se a semana começa na segunda (true) ou no domingo (false).
  final bool weekStartsMonday;

  /// O perfil só está completo quando a pessoa escolheu ao menos uma
  /// prioridade — é essa escolha que muda a Home.
  bool get isComplete => focus.isNotEmpty;

  UserProfile copyWith({
    String? name,
    bool clearName = false,
    Set<ProfileFocus>? focus,
    int? dailyGoal,
    bool? weekStartsMonday,
  }) {
    return UserProfile(
      name: clearName ? null : (name ?? this.name),
      focus: focus ?? this.focus,
      dailyGoal: (dailyGoal ?? this.dailyGoal).clamp(1, 10),
      weekStartsMonday: weekStartsMonday ?? this.weekStartsMonday,
    );
  }

  /// A prioridade principal, na ordem em que o enum foi declarado.
  ProfileFocus get primaryFocus {
    if (focus.isEmpty) return ProfileFocus.balance;
    return ProfileFocus.values.firstWhere(focus.contains);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfile &&
        other.name == name &&
        other.dailyGoal == dailyGoal &&
        other.weekStartsMonday == weekStartsMonday &&
        other.focus.length == focus.length &&
        other.focus.containsAll(focus);
  }

  @override
  int get hashCode => Object.hash(
        name,
        Object.hashAllUnordered(focus),
        dailyGoal,
        weekStartsMonday,
      );
}
