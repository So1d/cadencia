import 'package:flutter/material.dart';

import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';

/// Casca principal: mantém as quatro abas vivas com `IndexedStack`.
///
/// `IndexedStack` preserva o estado de cada aba (rolagem, campo de busca)
/// enquanto a pessoa troca de contexto — sem recarregar tudo a cada toque.
/// Os filtros em si vivem no `TaskQueryController`, acima desta casca, então
/// sobrevivem até a uma troca de aba que reconstruísse a tela.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Índice da aba Tarefas na barra de navegação.
  static const int _tasksTab = 2;

  int _index = 0;

  /// Só a casca sabe qual aba está aberta; a Home pede a navegação por
  /// callback em vez de importar a página de Tarefas.
  void _openTasks() => setState(() => _index = _tasksTab);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(onOpenTasks: _openTasks),
            const CalendarPage(),
            const TasksPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Hoje',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tarefas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
