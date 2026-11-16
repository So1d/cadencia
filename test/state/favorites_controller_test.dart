import 'package:cadencia/features/favorites/data/fake_favorites_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFavoritesRepository repository;

  FavoritesController build({List<String> seed = const []}) {
    repository = FakeFavoritesRepository(seed: seed, latency: Duration.zero);
    return FavoritesController(repository: repository);
  }

  test('começa vazio e sem favoritos', () {
    final favorites = build();

    expect(favorites.favoriteIds, isEmpty);
    expect(favorites.isFavorite('t1'), isFalse);
  });

  test('toggle adiciona no topo e devolve true', () {
    final favorites = build();

    expect(favorites.toggle('t1'), isTrue);
    expect(favorites.isFavorite('t1'), isTrue);
    expect(favorites.favoriteIds, ['t1']);
  });

  test('mais recente fica no índice 0', () {
    final favorites = build();

    favorites
      ..toggle('t1')
      ..toggle('t2')
      ..toggle('t3');

    expect(favorites.favoriteIds, ['t3', 't2', 't1']);
  });

  test('toggle no que já é favorito remove e devolve false', () {
    final favorites = build()..toggle('t1');

    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    expect(favorites.toggle('t1'), isFalse);
    expect(favorites.isFavorite('t1'), isFalse);
    expect(favorites.favoriteIds, isEmpty);
    expect(notificacoes, 1);
  });

  test('cada mudança notifica os ouvintes', () {
    final favorites = build();
    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    favorites
      ..toggle('t1')
      ..toggle('t2')
      ..remove('t1');

    expect(notificacoes, 3);
  });

  test('remove tira da relação sem alternar e não notifica à toa', () async {
    final favorites = build(seed: ['t1', 't2']);
    await favorites.load();

    favorites.remove('t1');
    expect(favorites.favoriteIds, ['t2']);

    favorites.remove('inexistente');
    expect(favorites.favoriteIds, ['t2']);
  });

  test('a lista exposta é somente leitura', () {
    final favorites = build()..toggle('t1');

    expect(
      () => favorites.favoriteIds.add('intruso'),
      throwsUnsupportedError,
    );
  });

  group('persistência', () {
    test('carrega a relação salva, mantendo a ordem', () async {
      final favorites = build(seed: ['t3', 't1', 't2']);

      expect(favorites.favoriteIds, isEmpty, reason: 'só depois do load');

      await favorites.load();

      expect(favorites.favoriteIds, ['t3', 't1', 't2']);
      expect(favorites.isFavorite('t2'), isTrue);
    });

    test('cada marcação grava a relação inteira na ordem atual', () async {
      final favorites = build();

      favorites
        ..toggle('t1')
        ..toggle('t2');
      await pumpEventQueue();

      expect(repository.saved, ['t2', 't1']);

      favorites.remove('t2');
      await pumpEventQueue();

      expect(repository.saved, ['t1']);
    });

    test('falha ao carregar começa vazio e não derruba a tela', () async {
      final favorites = FavoritesController(
        repository: FakeFavoritesRepository(
          latency: Duration.zero,
          shouldFail: true,
        ),
      );

      await favorites.load();

      expect(favorites.favoriteIds, isEmpty);
    });

    test('ids repetidos na origem não duplicam a relação', () async {
      final favorites = build(seed: ['t1', 't2', 't1']);

      await favorites.load();

      expect(favorites.favoriteIds, ['t1', 't2']);
    });
  });
}
