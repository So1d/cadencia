import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/task_priority.dart';
import 'task_priority_view.dart';

/// Resultado do diálogo de criação/edição de tarefa.
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.notes,
    this.dueDate,
    required this.priority,
  });

  final String title;
  final String? notes;
  final DateTime? dueDate;
  final TaskPriority priority;
}

/// Diálogo para criar ou editar uma tarefa.
class TaskDialog extends StatefulWidget {
  const TaskDialog({super.key, this.initial});

  /// Quando informado, o diálogo entra em modo edição.
  final TaskDraft? initial;

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late DateTime? _dueDate;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _notes = TextEditingController(text: widget.initial?.notes ?? '');
    _dueDate = widget.initial?.dueDate;
    _priority = widget.initial?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dueDate == null
        ? 'Sem data'
        : DateFormat('EEE, d MMM yyyy', 'pt_BR').format(_dueDate!);

    return AlertDialog(
      title: Text(widget.initial == null ? 'Nova tarefa' : 'Editar tarefa'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'O que precisa ser feito?',
                  hintText: 'Ex.: entregar o relatório',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(dateLabel, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      tooltip: 'Remover data',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // O rótulo e a cor vêm do próprio enum — sem switch repetido.
              SegmentedButton<TaskPriority>(
                showSelectedIcon: false,
                segments: [
                  for (final priority in TaskPriority.values)
                    ButtonSegment(
                      value: priority,
                      label: Text(priority.label),
                      icon: Icon(
                        priority.icon,
                        size: 16,
                        color: priority.color,
                      ),
                    ),
                ],
                selected: {_priority},
                onSelectionChanged: (selection) =>
                    setState(() => _priority = selection.first),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _canSave ? _submit : null,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      TaskDraft(
        title: title,
        notes: _notes.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
      ),
    );
  }
}
