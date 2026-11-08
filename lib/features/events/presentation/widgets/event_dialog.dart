import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';

/// Resultado do diálogo de criação/edição de evento.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.start,
    this.end,
    this.notes,
    required this.allDay,
  });

  final String title;
  final DateTime start;
  final DateTime? end;
  final String? notes;
  final bool allDay;
}

/// Diálogo para criar ou editar um evento da agenda.
class EventDialog extends StatefulWidget {
  const EventDialog({super.key, this.initialDay, this.initial});

  /// Dia pré-selecionado ao abrir.
  final DateTime? initialDay;

  /// Quando informado, o diálogo entra em modo edição.
  final EventDraft? initial;

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late DateTime _day;
  late TimeOfDay _time;
  late Duration _duration;
  late bool _allDay;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final now = DateTime.now();
    _title = TextEditingController(text: initial?.title ?? '');
    _notes = TextEditingController(text: initial?.notes ?? '');
    _day = initial?.start ?? widget.initialDay ?? now;
    _time = TimeOfDay.fromDateTime(initial?.start ?? now);
    _duration = initial?.end != null
        ? initial!.end!.difference(initial.start)
        : const Duration(hours: 1);
    _allDay = initial?.allDay ?? false;
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
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM yyyy', 'pt_BR').format(_day);
    final timeLabel = '${_time.hour.toString().padLeft(2, '0')}:'
        '${_time.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Text(widget.initial == null ? 'Novo evento' : 'Editar evento'),
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
                  labelText: 'Título do evento',
                  hintText: 'Ex.: reunião com a equipe',
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
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dia inteiro'),
                value: _allDay,
                onChanged: (value) => setState(() => _allDay = value),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(dateLabel, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  if (!_allDay) ...[
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(timeLabel),
                    ),
                  ],
                ],
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

    final start = _allDay
        ? DateTime(_day.year, _day.month, _day.day)
        : DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);

    Navigator.pop(
      context,
      EventDraft(
        title: title,
        start: start,
        end: _allDay ? null : start.add(_duration),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        allDay: _allDay,
      ),
    );
  }
}
