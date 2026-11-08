import 'package:cadencia/features/profile/data/user_profile_json.dart';
import 'package:cadencia/features/profile/domain/entities/profile_focus.dart';
import 'package:cadencia/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('perfil vazio não está completo', () {
      expect(UserProfile.empty.isComplete, isFalse);
      expect(UserProfile.empty.primaryFocus, ProfileFocus.balance);
    });

    test('perfil com prioridade está completo', () {
      const profile = UserProfile(focus: {ProfileFocus.deadlines});
      expect(profile.isComplete, isTrue);
      expect(profile.primaryFocus, ProfileFocus.deadlines);
    });

    test('meta diária é limitada entre 1 e 10', () {
      expect(const UserProfile().copyWith(dailyGoal: 0).dailyGoal, 1);
      expect(const UserProfile().copyWith(dailyGoal: 99).dailyGoal, 10);
      expect(const UserProfile().copyWith(dailyGoal: 5).dailyGoal, 5);
    });

    test('igualdade compara por valor', () {
      const a = UserProfile(
        name: 'Ana',
        focus: {ProfileFocus.events, ProfileFocus.deadlines},
        dailyGoal: 4,
        weekStartsMonday: false,
      );
      const b = UserProfile(
        name: 'Ana',
        focus: {ProfileFocus.deadlines, ProfileFocus.events},
        dailyGoal: 4,
        weekStartsMonday: false,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith limpa o nome', () {
      const profile = UserProfile(name: 'Ana');
      expect(profile.copyWith(clearName: true).name, isNull);
      expect(profile.copyWith(name: 'Bia').name, 'Bia');
    });
  });

  group('UserProfileJson', () {
    test('ida e volta por JSON preserva os campos', () {
      const profile = UserProfile(
        name: 'Everton',
        focus: {ProfileFocus.deadlines, ProfileFocus.events},
        dailyGoal: 6,
        weekStartsMonday: false,
      );

      final copy = userProfileFromJson(profile.toJson());

      expect(copy, profile);
    });

    test('JSON corrompido cai nos padrões', () {
      final profile = userProfileFromJson({
        'name': '   ',
        'focus': ['texto', 99],
        'daily_goal': 42,
        'week_starts_monday': 'sim',
      });

      expect(profile.name, isNull);
      expect(profile.focus, isEmpty);
      expect(profile.dailyGoal, 10);
      expect(profile.weekStartsMonday, isTrue);
    });

    test('lista de prioridades desconhecida vira vazia', () {
      final profile = userProfileFromJson({'focus': 'nada'});
      expect(profile.focus, isEmpty);
    });
  });
}
