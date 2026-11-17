# Etapa 2: busca e filtros como estado derivado

O laboratório Explorar (7 etapas) pede uma tela de catálogo com busca, filtros
combináveis, ordenação e estados de lista. Aqui ele foi aplicado ao Cadência, na
aba Tarefas. As etapas 1 a 7 do material estão cobertas; o que mudou são os
nomes e os recortes, porque o domínio do Cadência é tarefa, não estabelecimento.

## 1. O que virou o quê

| Laboratório | Cadência |
| --- | --- |
| `ExploreFilters` | `TaskQuery` |
| Categorias (Café, Padaria...) | Situação (pendentes, feitas, todas) e prioridades |
| Opções alimentares | Prioridades (Baixa, Média, Alta), combinadas com OU |
| "Atende ao meu perfil" | Não se aplica: o perfil define a ordem da Home, não um recorte de tarefas |
| "Só favoritos" | "Favoritas", com a contagem no rótulo do chip |
| `ExploreSort` | `TaskSort` (Padrão, Prazo, Prioridade, A-Z) |
| `applyExploreFilters` | `applyTaskQuery` |
| `ExploreController` | `TaskQueryController` |
| `ExplorePage` | `TasksPage` |
| Home → Explorar | Home → Tarefas |

Duas adaptações conscientes:

- **O perfil não entra como filtro.** No laboratório ele alimenta o chip "atende
  ao meu perfil". No Cadência, `ProfileFocus` decide qual seção abre primeiro na
  Home, e `dailyGoal` alimenta o progresso do dia. Transformar isso num recorte
  de tarefas seria inventar uma regra que o app não tem. A tela continua lendo
  três fontes: catálogo, consulta e favoritos.
- **Prazo substitui as categorias.** "Vence hoje", "Semana" e "Atrasadas"
  escondem tarefas de verdade e combinam com o resto, como as categorias do
  laboratório.

## 2. Domínio puro

`lib/features/tasks/domain/task_query.dart`

- Campos `final` num construtor `const`.
- `copyWith` devolve cópia; campo omitido preserva o valor.
- Igualdade **por conteúdo**: prioridades são comparadas com `containsAll` e o
  hash usa `Object.hashAllUnordered`, porque `Set` não tem igualdade por
  conteúdo. Sem isso, toda reconstrução pareceria uma mudança de filtro.
- `activeCount` conta grupos, não itens: três prioridades marcadas ainda são um
  filtro. `hasFilters` deriva dele.
- `cleared()` volta ao inicial e **preserva a ordenação**: ordem não esconde
  nada, é preferência de leitura.

`lib/features/tasks/domain/task_query_engine.dart`

Função pura, sem Flutter, `BuildContext`, `Provider` ou I/O:

```dart
List<Task> applyTaskQuery(
  List<Task> tasks,
  TaskQuery query, {
  List<String> favoriteIds = const [],
  DateTime? now,
})
```

Semântica:

| Grupo | Regra |
| --- | --- |
| Situação | pendentes, feitas ou todas |
| Texto | todas as palavras, sem acento e sem caixa, no título e nas observações |
| Prioridades | OU dentro do grupo, E com os demais grupos |
| Prazo | hoje, próximos 7 dias ou vencidas |
| Favoritas | interseção com a relação de ids |

A ordenação acontece numa cópia, com desempate por título e id. Sem desempate,
`List.sort` deixa empates em ordem imprevisível. No filtro de favoritas, a ordem
padrão é a de escolha (a marcada por último primeiro); as outras ordenações
continuam disponíveis no menu.

`lib/core/utils/search_text.dart` concentra a normalização de texto e a quebra
em palavras.

## 3. Estado derivado

`lib/features/tasks/presentation/task_query_controller.dart` guarda **só** a
consulta. O catálogo continua no `ScheduleController` e a lista visível é
calculada no build:

```dart
final query = context.watch<TaskQueryController>().query;
final favorites = context.watch<FavoritesController>();
final visible = applyTaskQuery(
  schedule.tasks,
  query,
  favoriteIds: favorites.favoriteIds,
);
```

Consequência: favoritar em outra aba ou editar uma tarefa atualiza a lista sem
ninguém precisar recalcular. Guardar `_visible` no controlador seria pedir para
ele envelhecer.

O controlador ignora `next == query` e não notifica sem mudança. Os quatro
estados da lista continuam vindo do `ScheduleController` (loading, error, empty,
success), então não há um segundo estado de carga para desencontrar.

## 4. Busca com debounce

`lib/features/tasks/presentation/widgets/task_search_field.dart`

- `Timer` de 300 ms reiniciado a cada tecla: só o último agendamento executa.
- Enter e o botão de limpar agem na hora.
- `didUpdateWidget` sincroniza o campo com a consulta quando ela muda por fora
  (limpar filtros, atalho da Home). A segunda condição
  (`widget.value != _controller.text`) evita laço e salto do cursor.
- `dispose` cancela o timer e libera o `TextEditingController`.

## 5. Interface

- Filtros em `Wrap`, nunca em rolagem horizontal: com fonte grande, chip
  rolável esconde opções.
- `ChoiceChip` para situação, `FilterChip` para favoritas, prioridades e prazo.
  Tocar de novo no prazo marcado volta a "qualquer prazo".
- Contagem numa `Semantics(liveRegion: true, ...)`: o leitor de tela anuncia o
  novo total.
- Barra de resultados com "Limpar filtros (n)" e menu de ordenação.
- Lista em `CustomScrollView`: cabeçalho de filtros rola junto com os itens, e
  os quatro estados ocupam `SliverFillRemaining`.
- Estado vazio com ação: "Limpar filtros" quando há recorte, "Criar tarefa"
  quando o catálogo está vazio de verdade.

## 6. Home e casca

- A casca é quem sabe a aba aberta. A Home pede navegação por callback
  (`onOpenTasks`) e entrega o recorte pelo `TaskQueryController`: dois canais,
  um para dados e outro para navegação.
- A Home ganhou um campo-botão de busca e dois atalhos: "Alta prioridade" e
  "Vence hoje". Atalho é `showOnly`, que começa do zero; chip é `toggle`, que
  soma ou tira.
- "Ver todas as tarefas" chama `clear()` e abre a aba.
- `IndexedStack` mantém as abas vivas, e os filtros vivem no controlador acima
  da casca: sobrevivem à troca de aba.

## 7. Roteiro de demonstração

| Passo | O que mostrar |
| --- | --- |
| A | Abra Tarefas: campo de busca, chips e contagem "N tarefas encontradas". |
| B | Digite "relatorio": a lista espera o silêncio e acha "Relatório" sem acento. |
| C | Marque "Alta" e "Atrasadas": os grupos se combinam (E entre grupos). |
| D | Toque em "Limpar filtros (2)": tudo volta e o campo esvazia junto. |
| E | Na Home, toque em "Alta prioridade": a aba abre já recortada. |
| F | Na Home, "Ver todas as tarefas": abre com os filtros limpos. |
| G | Vá para Perfil e volte: o texto digitado continua lá. |

## 8. Testes

`flutter test` passa com 138 testes e `flutter analyze` sem avisos.

- `test/domain/task_query_test.dart`: igualdade com `Set`, `copyWith`,
  `activeCount`, `cleared` preservando a ordenação.
- `test/domain/task_query_engine_test.dart`: E/OU, acentos, observações, prazos,
  quatro ordenações, desempate e catálogo intacto.
- `test/state/task_query_controller_test.dart`: notificação só com mudança,
  toggle de prazo e prioridade, `clear` e `showOnly`.
- `test/widgets/tasks_page_test.dart`: debounce com relógio simulado, campo
  sincronizado, chips, filtro de favoritas, ordenação, detalhe, alvos de toque,
  rótulos e overflow em 320x640 com fonte 200%.
- `test/widgets/task_query_flow_test.dart`: integração pela casca (atalho da
  Home, "Ver todas", busca, persistência entre abas) com o app inteiro.

## 9. Arquivos

- `lib/features/tasks/domain/task_query.dart`
- `lib/features/tasks/domain/task_query_engine.dart`
- `lib/core/utils/search_text.dart`
- `lib/features/tasks/presentation/task_query_controller.dart`
- `lib/features/tasks/presentation/widgets/task_search_field.dart`
- `lib/features/tasks/presentation/widgets/task_filter_chips.dart`
- `lib/features/tasks/presentation/widgets/task_results_bar.dart`
- `lib/features/tasks/presentation/pages/tasks_page.dart`
- `lib/app/shell/app_shell.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/app/cadencia_app.dart`
