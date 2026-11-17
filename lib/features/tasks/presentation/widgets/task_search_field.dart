import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';

/// Campo de busca das tarefas, com atraso antes de avisar quem escuta.
///
/// Cada letra digitada reinicia a espera: só o último agendamento executa. Sem
/// isso, "padaria" filtraria sete vezes e reconstruiria a lista sete vezes.
///
/// O campo é um `StatefulWidget` porque tem dono próprio (o
/// `TextEditingController`) e um `Timer` que precisa ser cancelado no
/// `dispose`. O texto exibido **acompanha** o estado da consulta: quando a
/// pessoa toca em "Limpar filtros", o campo esvazia junto em vez de mentir.
class TaskSearchField extends StatefulWidget {
  const TaskSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  /// Texto atual da consulta.
  final String value;

  /// Chamado depois do silêncio de [debounce].
  final ValueChanged<String> onChanged;

  /// Tempo de silêncio. Parâmetro para o teste não esperar 300 ms de verdade.
  final Duration debounce;

  @override
  State<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends State<TaskSearchField> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(TaskSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A segunda condição evita laço e salto do cursor: só reescreve o campo
    // quando a consulta mudou por fora (limpar filtros, atalho da Home) e o
    // texto na tela não é o mesmo.
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _timer?.cancel();
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _agendar(String text) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(text));
  }

  void _limpar() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    // Limpar não espera: a lista deve voltar na hora.
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (text) {
        setState(() {});
        _agendar(text);
      },
      onSubmitted: (text) {
        // Enter/busca do teclado não tem motivo para esperar.
        _timer?.cancel();
        widget.onChanged(text);
      },
      decoration: InputDecoration(
        hintText: 'Buscar tarefas',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close, size: 18),
                onPressed: _limpar,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
