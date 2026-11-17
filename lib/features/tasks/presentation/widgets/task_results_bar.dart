import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/task_query.dart';

/// Barra entre os filtros e a lista: quantas tarefas sobraram, o atalho para
/// limpar e a ordenação.
///
/// A contagem fica numa `liveRegion`: quando a pessoa digita ou marca um chip,
/// o leitor de tela anuncia o novo total em vez de mudar o texto em silêncio.
///
/// A ordenação é um menu, não um dropdown de largura fixa: com fonte grande, o
/// dropdown estourava a linha. O texto aqui quebra e a linha continua inteira.
class TaskResultsBar extends StatelessWidget {
  const TaskResultsBar({
    super.key,
    required this.query,
    required this.count,
    required this.onClear,
    required this.onSort,
  });

  final TaskQuery query;
  final int count;
  final VoidCallback onClear;
  final ValueChanged<TaskSort> onSort;

  String get _countLabel =>
      count == 1 ? '1 tarefa encontrada' : '$count tarefas encontradas';

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(_countLabel, style: muted),
        ),
        if (query.hasFilters)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: Text('Limpar filtros (${query.activeCount})'),
          ),
        PopupMenuButton<TaskSort>(
          tooltip: 'Ordenar tarefas',
          initialValue: query.sort,
          onSelected: onSort,
          itemBuilder: (context) => [
            for (final sort in TaskSort.values)
              PopupMenuItem(value: sort, child: Text(sort.label)),
          ],
          child: ConstrainedBox(
            // Área de toque mínima de 48: com fonte grande o menu encolhia
            // para 40 e ficava abaixo do alvo recomendado.
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Ordenar: ${query.sort.label}',
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
