import 'package:cadencia/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O Material injeta vários estilos do tema via `DefaultTextStyle` (título de
/// AppBar, label de campo, título e conteúdo de diálogo, item de popup,
/// tooltip). Nesses pontos a família **não** é herdada: se o `TextStyle` do
/// tema não declarar a fonte, o texto sai na fonte do sistema.
void main() {
  testWidgets('nenhum texto sai fora da Fira Code', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          appBar: AppBar(title: const Text('Título do AppBar')),
          body: Column(
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Label')),
              const Tooltip(
                message: 'Dica',
                child: Icon(Icons.info),
              ),
              PopupMenuButton<String>(
                onSelected: (_) {},
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'a', child: Text('Item do menu')),
                ],
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: tester.element(find.byType(Column)),
                  builder: (_) => const AlertDialog(
                    title: Text('Título do diálogo'),
                    content: Text('Conteúdo do diálogo'),
                  ),
                ),
                child: const Text('Abrir diálogo'),
              ),
              const ListTile(title: Text('Tile'), subtitle: Text('Subtile')),
              const Chip(label: Text('Chip')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir diálogo'));
    await tester.pumpAndSettle();

    final foraDaFira = <String>[];
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      final family = rich.text.style?.fontFamily;
      if (family != 'Fira Code' && family != 'MaterialIcons') {
        foraDaFira.add('${rich.text.toPlainText()} -> ${family ?? 'sem fonte'}');
      }
    }

    expect(foraDaFira, isEmpty, reason: 'textos fora da Fira Code');
  });
}
