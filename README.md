# Cadência

Aplicativo de **calendário e tarefas** em Flutter, com identidade visual
brutalista escura e interface em português do Brasil.

O Cadência nasceu como exercício do curso e evoluiu para o mesmo nível de
funcionalidade do app de referência **CeliLac** (perfil que personaliza a Home,
shell com abas, detalhe de item, estados de carga e persistência local). O
domínio, porém, é próprio: **agenda e tarefas**, não um perfil alimentar.

---

## O que o app faz

- **Abertura (splash)**: carrega agenda e perfil e decide entre onboarding ou
  shell principal. Tempo mínimo de 900 ms para evitar "pisca" na tela.
- **Onboarding**: três etapas com opção de pular; a conclusão fica salva no
  aparelho.
- **Hoje**: saudação com o nome do perfil, cartão de progresso do dia contra a
  meta, convite para completar o perfil e as seções de tarefas/compromissos.
  A ordem das seções muda conforme a prioridade escolhida no perfil.
- **Agenda**: calendário mensal (`table_calendar`), marcadores nos dias com
  evento, lista dos compromissos do dia selecionado e criação rápida.
- **Tarefas**: filtros **Pendentes / Feitas / Todas** com contadores,
  conclusão por checkbox, edição, exclusão e prioridades.
- **Detalhe do evento**: capa com `Hero`, data/hora, observações e ações de
  editar/excluir.
- **Perfil**: nome opcional, prioridade (`Prazos`, `Agenda`, `Equilíbrio`),
  meta diária de 1 a 10 e início da semana (segunda ou domingo).
- **Estados de tela**: carregando, erro com "Tentar novamente", vazio com ação
  e sucesso — centralizados em `StatusView`.
- **Acessibilidade**: rótulos semânticos nos checkboxes, `Tooltip` nas ações,
  área de erro como `liveRegion` no formulário e contraste alto do tema.

O perfil é usado de verdade em quatro lugares:

1. nome na saudação da Home;
2. prioridade define a ordem das seções da Home;
3. meta diária alimenta o cartão de progresso;
4. início da semana muda o calendário.

---

## Como rodar

Pré-requisitos: Flutter 3.47+ / Dart 3.13+.

```bash
flutter pub get
flutter run
```

### Modos de demonstração

Os repositórios falsos permitem mostrar os estados sem quebrar dados reais:

```bash
# latência artificial de 5 s: mostra o estado de carregamento
flutter run --dart-define=CADENCIA_DEMO=slow

# falha simulada na primeira carga: mostra o erro e o retry recuperando
flutter run --dart-define=CADENCIA_DEMO=error
```

Sem `--dart-define`, o app usa os repositórios locais (`shared_preferences`).
Para rever o onboarding, limpe os dados do app (ou desinstale/reinstale).

### Qualidade

```bash
flutter analyze   # 0 issues
flutter test      # 67 testes
```

---

## Estrutura

```text
lib/
├── main.dart                      # inicializa datas pt_BR e sobe o CadenciaApp
├── app/
│   ├── app_dependencies.dart      # produção vs. demo (CADENCIA_DEMO)
│   ├── cadencia_app.dart          # MaterialApp, tema, escopos, rota inicial
│   ├── common/widgets/            # StatusMessage (estados simples)
│   ├── routes/fade_route.dart     # transição usada nas telas de detalhe
│   ├── shell/app_shell.dart       # IndexedStack + NavigationBar (4 abas)
│   └── theme/                     # cores, espaçamentos, raios, layout, ThemeData
├── core/
│   ├── load_status.dart           # loading / success / empty / error
│   ├── utils/                     # datas e geração de id
│   └── widgets/                   # LoadingView, ErrorView, EmptyView, StatusView...
├── features/
│   ├── startup/                   # splash
│   ├── onboarding/                # domínio + armazenamento + páginas
│   ├── home/                      # aba Hoje + widgets
│   ├── calendar/                  # aba Agenda
│   ├── events/                    # evento: domínio, dados, detalhe, diálogo
│   ├── tasks/                     # tarefa: domínio, dados, aba, diálogo
│   └── profile/                   # perfil: domínio, dados, controller, páginas
└── state/
    ├── schedule_controller.dart   # regras de agenda + tarefas
    └── schedule_scope.dart        # InheritedNotifier do controller
```

Cada feature segue as mesmas camadas:

- **domain**: modelos imutáveis e contratos de repositório;
- **data**: implementação real (`Local*`) e falsa (`Fake*`);
- **presentation**: páginas, widgets, controllers e escopos.

Assim, a tela não sabe se o dado veio do aparelho ou de um fake: quem decide é
`AppDependencies`.

---

## Como o estado circula

```text
main()
  └── CadenciaApp
        ├── ScheduleScope  → ScheduleController  → TaskRepository / EventRepository
        ├── ProfileScope   → ProfileController   → ProfileRepository
        └── MaterialApp → SplashPage → Onboarding ou AppShell
```

- `ScheduleController` estende `ChangeNotifier` e concentra as regras de
  eventos e tarefas (ordenação, filtros, progresso, CRUD e persistência).
- `ScheduleScope` é um `InheritedNotifier`: quem chama `ScheduleScope.of(context)`
  é reconstruído automaticamente quando o controller notifica.
- `ProfileController` faz o mesmo para as preferências do perfil.
- Os escopos ficam **acima** do `MaterialApp`, então rotas empilhadas (detalhe,
  formulário) também enxergam o estado.

Fluxo de uma ação, por exemplo "concluir tarefa":

```text
Checkbox → ScheduleController.toggleTask()
         → atualiza a lista em memória
         → notifica ouvintes (telas se reconstroem)
         → grava JSON via TaskRepository (sem bloquear a UI)
```

A gravação é "otimista": a interface responde na hora e o repositório salva em
seguida. Se o disco falhar, o app não trava.

---

## Persistência

| Chave                   | Conteúdo                                      |
| ----------------------- | --------------------------------------------- |
| `cadencia_tasks_v1`     | envelope JSON `{schema_version, items: [...]}` |
| `cadencia_events_v1`    | envelope JSON `{schema_version, items: [...]}` |
| `cadencia_profile_v1`   | perfil + `schema_version`                     |
| `onboardingCompleted`   | booleano do onboarding                        |

A leitura tolera dado corrompido e formato antigo (lista solta), partindo do
vazio em vez de derrubar o app.

---

## Testes

- **domínio**: JSON de tarefa/evento/perfil, valores inválidos, `copyWith`,
  igualdade e limites.
- **dados**: ida e volta no `shared_preferences` em memória, formato legado e
  dado corrompido.
- **estado**: carga, erro + retry, ordenação, filtros, CRUD, progresso e
  idempotência do carregamento do perfil.
- **widgets**: os quatro estados, Home personalizada, formulário com validação
  e descarte, filtros de tarefas, calendário, detalhe de evento, navegação
  entre abas e conflito de `Hero`.

Os testes usam `InMemorySharedPreferencesAsync` e repositórios falsos com
latência zero, sem depender de emulador.

---

## Decisões que valem explicar

- **Sem `provider`/`riverpod`**: `ChangeNotifier` + `InheritedNotifier` cobre o
  tamanho do app e deixa explícito o fluxo que o curso ensina.
- **Repositórios como contratos**: trocar `shared_preferences` por API ou banco
  não exige mudar nenhuma tela.
- **Estados explícitos**: `LoadStatus` + `StatusView` impedem o clássico "tela
  branca" quando a carga falha.
- **Perfil opcional**: o app funciona sem nome; a prioridade é o que torna o
  perfil "completo", pois é ela que muda o comportamento.
- **Datas normalizadas**: tarefas guardam só o dia; eventos de dia inteiro
  também. Isso evita bugs de fuso e comparações por horário.
- **Hero com tag por tela**: Home e Agenda vivem na mesma rota (`IndexedStack`);
  prefixos diferentes (`home-event-...`, `calendar-event-...`) evitam tags
  duplicadas.
