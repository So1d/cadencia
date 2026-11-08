import 'package:flutter/widgets.dart';

import 'schedule_controller.dart';

/// Disponibiliza o [ScheduleController] para a árvore inteira.
///
/// `InheritedNotifier` faz duas coisas: entrega o controlador e reconstrói
/// quem depende dele sempre que `notifyListeners()` é chamado.
class ScheduleScope extends InheritedNotifier<ScheduleController> {
  const ScheduleScope({
    super.key,
    required ScheduleController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Lê e se inscreve: quem chama é reconstruído quando a agenda muda.
  /// Use no `build`.
  static ScheduleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ScheduleScope>();
    assert(scope != null, 'Nenhum ScheduleScope acima deste widget.');
    return scope!.notifier!;
  }

  /// Só lê, sem se inscrever. Use em callbacks e no `initState`.
  static ScheduleController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ScheduleScope>();
    assert(scope != null, 'Nenhum ScheduleScope acima deste widget.');
    return scope!.notifier!;
  }
}
