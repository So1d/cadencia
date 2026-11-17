import 'package:cadencia/features/favorites/data/fake_favorites_repository.dart';
import 'package:cadencia/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:cadencia/features/favorites/presentation/favorites_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repositório que demora mais na primeira gravação: sem fila, a segunda
/// chegaria ao disco antes da primeira.
class _RepoLento implements FavoritesRepository {
  final List<List<String>> gravacoes = [];

  @override
  Future<List<String>> fetchAll() async => const [];

  @override
  Future<void> saveAll(List<String> taskIds) async {
    await Future<void>.delayed(
      Duration(milliseconds: gravacoes.isEmpty ? 20 : 1),
    );
    gravacoes.add([...taskIds]);
  }
}

/// Repositório que falha só na primeira gravação.
class _RepoFalhaUmaVez implements FavoritesRepository {
  bool falhou = false;
  final List<List<String>> gravacoes = [];

  @override
  Future<List<String>> fetchAll() async => const [];

  @override
  Future<void> saveAll(List<String> taskIds) async {
    if (!falhou) {
      falhou = true;
      throw Exception('disco cheio');
    }
    gravacoes.add([...taskIds]);
  }
}

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

  test('toggle adiciona no topo e devolve true', () async {
    final favorites = build();

    expect(await favorites.toggle('t1'), isTrue);
    expect(favorites.isFavorite('t1'), isTrue);
    expect(favorites.favoriteIds, ['t1']);
  });

  test('mais recente fica no índice 0', () async {
    final favorites = build();

    await favorites.toggle('t1');
    await favorites.toggle('t2');
    await favorites.toggle('t3');

    expect(favorites.favoriteIds, ['t3', 't2', 't1']);
  });

  test('toggle no que já é favorito remove e devolve false', () async {
    final favorites = build();
    await favorites.toggle('t1');

    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    expect(await favorites.toggle('t1'), isFalse);
    expect(favorites.isFavorite('t1'), isFalse);
    expect(favorites.favoriteIds, isEmpty);
    expect(notificacoes, 1);
  });

  test('cada mudança notifica os ouvintes', () async {
    final favorites = build();
    var notificacoes = 0;
    favorites.addListener(() => notificacoes++);

    await favorites.toggle('t1');
    await favorites.toggle('t2');
    favorites.remove('t1');

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
    final favorites = build();

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

      await favorites.toggle('t1');
      await favorites.toggle('t2');

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

    test('falha ao gravar desfaz a marcação e relança', () async {
      final favorites = FavoritesController(
        repository: FakeFavoritesRepository(
          latency: Duration.zero,
          shouldFailSave: true,
        ),
      );
      var notificacoes = 0;
      favorites.addListener(() => notificacoes++);

      await expectLater(favorites.toggle('t1'), throwsException);

      expect(favorites.isFavorite('t1'), isFalse);
      expect(favorites.favoriteIds, isEmpty);
      expect(
        notificacoes,
        2,
        reason: 'aplica na hora e desfaz quando o disco recusa',
      );
    });

    test('gravações em sequência não chegam ao disco fora de ordem',
        () async {
      final repo = _RepoLento();
      final favorites = FavoritesController(repository: repo);

      // Sem esperar a primeira, o segundo toggle já entra na fila.
      final primeira = favorites.toggle('t1');
      await favorites.toggle('t2');
      await primeira;

      expect(repo.gravacoes.last, ['t2', 't1']);
    });

    test('uma falha não trava as gravações seguintes', () async {
      final repo = _RepoFalhaUmaVez();
      final favorites = FavoritesController(repository: repo);

      await expectLater(favorites.toggle('t1'), throwsException);

      expect(await favorites.toggle('t2'), isTrue);
      expect(favorites.favoriteIds, ['t2']);
      expect(repo.gravacoes, [
        ['t2'],
      ]);
    });
  });
}
