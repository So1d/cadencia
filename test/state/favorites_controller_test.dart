import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('começa vazio e sem favoritos', () {
    final favorites = FavoritesController();

    expect(favorites.favoriteIds, isEmpty);
    expect(favorites.isFavorite('t1'), isFalse);
  });

  test('toggle adiciona no topo e devolve true', () {
    final favorites = FavoritesController();

    expect(favorites.toggle('t1'), isTrue);
    expect(favorites.isFavorite('t1'), isTrue);
    expect(favorites.favoriteIds, ['t1']);
  });

  test('mais recente fica no índice 0', () {
    final favorites = FavoritesController();

    favorites
      ..toggle('t1')
      ..toggle('t2')
      ..toggle('t3');

    expect(favorites.favoriteIds, ['t3', 't2', 't1']);
  });

  test('toggle no que já é favorito remove e devolve false', () {
    final favorites = FavoritesController()..toggle('t1');

    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    expect(favorites.toggle('t1'), isFalse);
    expect(favorites.isFavorite('t1'), isFalse);
    expect(favorites.favoriteIds, isEmpty);
    expect(notificacoes, 1);
  });

  test('cada mudança notifica os ouvintes', () {
    final favorites = FavoritesController();
    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    favorites
      ..toggle('t1')
      ..toggle('t2')
      ..remove('t1');

    expect(notificacoes, 3);
  });

  test('remove tira da relação sem alternar e não notifica à toa', () {
    final favorites = FavoritesController(initialIds: ['t1', 't2']);

    favorites.remove('t1');
    expect(favorites.favoriteIds, ['t2']);

    favorites.remove('inexistente');
    expect(favorites.favoriteIds, ['t2']);
  });

  test('a lista exposta é somente leitura', () {
    final favorites = FavoritesController()..toggle('t1');

    expect(
      () => favorites.favoriteIds.add('intruso'),
      throwsUnsupportedError,
    );
  });

  test('semente inicial ignora ids repetidos', () {
    final favorites = FavoritesController(initialIds: ['t1', 't2', 't1']);

    expect(favorites.favoriteIds, ['t1', 't2']);
    expect(favorites.isFavorite('t1'), isTrue);
  });
}
