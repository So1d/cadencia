import 'package:cadencia/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('primeira execução: splash leva pro onboarding',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});

    await tester.pumpWidget(const CadenciaApp());
    expect(find.text('CADÊNCIA'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Organize seu dia'), findsOneWidget);
  });

  testWidgets('segunda execução: splash leva direto pra Home',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboardingCompleted': true});

    await tester.pumpWidget(const CadenciaApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('HOME PROVISÓRIA'), findsOneWidget);
  });
}
