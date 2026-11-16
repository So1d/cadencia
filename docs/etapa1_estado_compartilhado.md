# Etapa 1 — Estado compartilhado no Cadência

**Entidade escolhida:** tarefas. Cada `Task` nasce com um `id` único (UUID curto gerado em
`Task`), e é esse id que reconhece o mesmo item na listagem, na Home e no detalhe.

**Onde está o controlador:** `lib/features/favorites/presentation/favorites_controller.dart`,
um `ChangeNotifier` que guarda apenas ids. Uma `List<String>` preserva a ordem de escolha (o
favorito mais recente fica no índice 0) e um `Set<String>` responde `isFavorite(id)` em tempo
constante, consulta feita no build de cada linha. A entidade em si continua na agenda
(`ScheduleController`): duplicar a `Task` dentro do controlador de favoritos faria a cópia ficar
desatualizada depois de uma edição.

**Persistência:** o controlador depende de um `FavoritesRepository` (contrato de leitura/gravação
da relação de ids). A implementação `LocalFavoritesRepository` grava em `shared_preferences` sob a
chave `cadencia_favorites_v1`, num envelope com `schema_version`, e tolera lista solta e dado
corrompido. A relação é carregada no `initState` de `CadenciaApp` e regravada a cada marcação,
remoção ou exclusão de tarefa. A etapa permite que a seleção se perca ao reiniciar; aqui ela é
mantida, inclusive a ordem.

**Injeção:** `ChangeNotifierProvider<FavoritesController>` em `CadenciaApp`, acima do
`MaterialApp`, para que as rotas empilhadas no `Navigator` (o detalhe da tarefa) também alcancem o
mesmo controlador. As telas leem com `context.watch` dentro do `build` e disparam ações com
`context.read` nos callbacks.

**Telas que compartilham o estado:** aba Tarefas (estrela da linha, filtro "Favoritas (n)" e
contagem), Home (tarefas de hoje) e detalhe da tarefa (`TaskDetailsPage`), que repete a estrela na
AppBar.

**Por que `setState` isolado não bastaria:** cada tela ficaria com a própria cópia do booleano e a
marcação feita em uma não chegaria na outra, exigindo passar o valor de tela em tela ou sincronizar
na mão a cada navegação. Com uma fonte única, marcar no detalhe já aparece na listagem (e vice-versa)
sem comunicação direta entre as telas, e a contagem do filtro acompanha sozinha.

## Como demonstrar

| Teste | Passos |
| --- | --- |
| A | Marque a estrela de uma tarefa na listagem e abra o detalhe: a estrela já está marcada. |
| B | No detalhe, desmarque a estrela e volte: a listagem e a contagem "Favoritas (n)" refletem a remoção. |
| C | Marque duas tarefas em sequência e abra o filtro "Favoritas": a última marcada aparece primeiro. |
| D | No filtro "Favoritas", desmarque as duas pela estrela: lista e contagem atualizam e, vazia, aparece a mensagem orientativa. |
| E | Feche e abra o app: os favoritos continuam, na mesma ordem (a etapa permite perder; aqui persiste). |

## Arquivos

- `lib/features/favorites/presentation/favorites_controller.dart` — o controlador.
- `lib/features/favorites/domain/repositories/favorites_repository.dart` — contrato de persistência.
- `lib/features/favorites/data/local_favorites_repository.dart` — gravação no aparelho.
- `lib/features/favorites/presentation/widgets/favorite_button.dart` — botão acessível, reusado na linha e no detalhe.
- `lib/features/tasks/presentation/pages/task_details_page.dart` — segundo ponto de interação.
- `lib/features/tasks/presentation/pages/tasks_page.dart` — filtro "Favoritas" e estrela da linha.
- `lib/features/home/presentation/pages/home_page.dart` — mesma estrela nas tarefas de hoje.
- `test/state/favorites_controller_test.dart`, `test/widgets/task_details_test.dart` — testes A, B e da estrutura.
