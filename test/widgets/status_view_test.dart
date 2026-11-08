import 'package:cadencia/core/load_status.dart';
import 'package:cadencia/core/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('loading mostra indicador', (tester) async {
    await tester.pumpWidget(
      wrap(
        StatusView(
          status: LoadStatus.loading,
          isEmpty: false,
          onRetry: () {},
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('conteúdo'), findsNothing);
  });

  testWidgets('erro mostra mensagem e botão de tentar novamente',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      wrap(
        StatusView(
          status: LoadStatus.error,
          isEmpty: false,
          onRetry: () => retries++,
          errorMessage: 'Deu ruim.',
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('Deu ruim.'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
  });

  testWidgets('vazio mostra convite e ação', (tester) async {
    var actions = 0;
    await tester.pumpWidget(
      wrap(
        StatusView(
          status: LoadStatus.success,
          isEmpty: true,
          onRetry: () {},
          emptyMessage: 'Nada aqui.',
          emptyAction: TextButton(
            onPressed: () => actions++,
            child: const Text('Criar'),
          ),
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('Nada aqui.'), findsOneWidget);
    await tester.tap(find.text('Criar'));
    expect(actions, 1);
    expect(find.text('conteúdo'), findsNothing);
  });

  testWidgets('success mostra o conteúdo', (tester) async {
    await tester.pumpWidget(
      wrap(
        StatusView(
          status: LoadStatus.success,
          isEmpty: false,
          onRetry: () {},
          child: const Text('conteúdo'),
        ),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);
  });
}
