import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_status.dart';
import '../core/utils/date_helpers.dart';
import '../features/events/domain/calendar_event.dart';
import '../features/events/domain/repositories/event_repository.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/domain/task.dart';
import '../features/tasks/domain/task_priority.dart';

/// Estado da agenda: eventos e tarefas.
///
/// Não sabe **como** os dados são lidos ou gravados: conversa apenas com os
/// repositórios definidos no domínio. Trocar a fonte (aparelho, servidor,
/// dado falso) não mexe em nenhuma tela.
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required TaskRepository taskRepository,
    required EventRepository eventRepository,
  })  : _tasks = taskRepository,
        _events = eventRepository;

  final TaskRepository _tasks;
  final EventRepository _events;

  final List<Task> _taskList = [];
  final List<CalendarEvent> _eventList = [];

  LoadStatus _status = LoadStatus.loading;

  /// Estado da carga inicial: loading, success ou error.
  ///
  /// O `empty` de cada coleção é calculado por [statusFor], porque uma lista
  /// pode estar vazia enquanto a outra tem registros.
  LoadStatus get status => _status;

  /// Lê tudo do repositório. É o que a tela de abertura aguarda.
  Future<void> init() async {
    // Primeiro "cede" para o framework: notificar ouvintes nunca deve
    // acontecer de forma síncrona dentro de um build.
    await null;
    _status = LoadStatus.loading;
    notifyListeners();

    try {
      final tasks = await _tasks.fetchAll();
      final events = await _events.fetchAll();
      _taskList
        ..clear()
        ..addAll(tasks);
      _eventList
        ..clear()
        ..addAll(events);
      _status = LoadStatus.success;
    } catch (error) {
      debugPrint('Falha ao carregar dados: $error');
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Estado de uma coleção: herda a carga global e, havendo consulta
  /// bem-sucedida, vira [LoadStatus.empty] quando a lista não tem nada.
  LoadStatus statusFor(Iterable<Object?> items) => switch (status) {
        LoadStatus.loading => LoadStatus.loading,
        LoadStatus.error => LoadStatus.error,
        _ => items.isEmpty ? LoadStatus.empty : LoadStatus.success,
      };

  void _persist() {
    unawaited(_tasks.saveAll(_taskList));
    unawaited(_events.saveAll(_eventList));
  }

  // ---------------------------------------------------------------- eventos

  List<CalendarEvent> get events => List.unmodifiable(_eventList);

  /// Eventos de um dia, com "dia inteiro" primeiro e depois por horário.
  List<CalendarEvent> eventsOfDay(DateTime day) {
    final list = _eventList.where((event) => mesmoDia(event.start, day)).toList()
      ..sort((a, b) {
        if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
        return a.start.compareTo(b.start);
      });
    return List.unmodifiable(list);
  }

  int eventsCountOfDay(DateTime day) => eventsOfDay(day).length;

  Set<DateTime> eventDaysInMonth(DateTime month) => {
        for (final event in _eventList)
          if (event.start.year == month.year &&
              event.start.month == month.month)
            dateOnly(event.start),
      };

  void addEvent({
    required String title,
    required DateTime start,
    DateTime? end,
    String? notes,
    bool allDay = false,
  }) {
    _eventList.add(
      CalendarEvent(
        title: title,
        start: allDay ? dateOnly(start) : start,
        end: allDay ? null : end,
        notes: _cleanNotes(notes),
        allDay: allDay,
      ),
    );
    _persist();
    notifyListeners();
  }

  void updateEvent(
    CalendarEvent event, {
    required String title,
    required DateTime start,
    DateTime? end,
    String? notes,
    bool allDay = false,
  }) {
    final index = _eventList.indexOf(event);
    if (index < 0) return;
    _eventList[index] = event.copyWith(
      title: title,
      start: allDay ? dateOnly(start) : start,
      end: end,
      clearEnd: allDay || end == null,
      notes: _cleanNotes(notes),
      clearNotes: _cleanNotes(notes) == null,
      allDay: allDay,
    );
    _persist();
    notifyListeners();
  }

  void removeEvent(CalendarEvent event) {
    _eventList.remove(event);
    _persist();
    notifyListeners();
  }

  // ----------------------------------------------------------------- tarefas

  List<Task> get tasks => List.unmodifiable(_taskList);

  /// Ordem de leitura: pendentes primeiro; com data antes de sem data; data
  /// mais próxima primeiro; prioridade alta desempata; título por último.
  List<Task> get tasksSorted {
    final list = [..._taskList];
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;

      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue == null) {
        return _byPriorityThenTitle(a, b);
      }
      if (aDue == null) return 1;
      if (bDue == null) return -1;

      final byDate = aDue.compareTo(bDue);
      return byDate != 0 ? byDate : _byPriorityThenTitle(a, b);
    });
    return List.unmodifiable(list);
  }

  static int _byPriorityThenTitle(Task a, Task b) {
    final byPriority = b.priority.value.compareTo(a.priority.value);
    return byPriority != 0 ? byPriority : a.title.compareTo(b.title);
  }

  List<Task> get pendingTasks =>
      tasksSorted.where((task) => !task.done).toList(growable: false);

  List<Task> tasksOfDay(DateTime day) => tasksSorted
      .where((task) => task.dueDate != null && mesmoDia(task.dueDate!, day))
      .toList(growable: false);

  /// Progresso geral (0 a 1) de todas as tarefas.
  double get progress {
    if (_taskList.isEmpty) return 0;
    final done = _taskList.where((task) => task.done).length;
    return done / _taskList.length;
  }

  /// Progresso das tarefas que vencem hoje (0 a 1).
  double progressOfDay(DateTime day) {
    final tasks = tasksOfDay(day);
    if (tasks.isEmpty) return 0;
    final done = tasks.where((task) => task.done).length;
    return done / tasks.length;
  }

  void addTask({
    required String title,
    String? notes,
    DateTime? dueDate,
    required TaskPriority priority,
  }) {
    _taskList.add(
      Task(
        title: title,
        notes: _cleanNotes(notes),
        dueDate: dueDate == null ? null : dateOnly(dueDate),
        priority: priority,
      ),
    );
    _persist();
    notifyListeners();
  }

  void toggleTask(Task task, bool value) {
    final index = _taskList.indexOf(task);
    if (index < 0) return;
    _taskList[index] = task.copyWith(done: value);
    _persist();
    notifyListeners();
  }

  void updateTask(
    Task task, {
    required String title,
    String? notes,
    DateTime? dueDate,
    required TaskPriority priority,
  }) {
    final index = _taskList.indexOf(task);
    if (index < 0) return;
    _taskList[index] = task.copyWith(
      title: title,
      notes: _cleanNotes(notes),
      clearNotes: _cleanNotes(notes) == null,
      dueDate: dueDate == null ? null : dateOnly(dueDate),
      clearDueDate: dueDate == null,
      priority: priority,
    );
    _persist();
    notifyListeners();
  }

  void removeTask(Task task) {
    _taskList.remove(task);
    _persist();
    notifyListeners();
  }

  static String? _cleanNotes(String? notes) {
    final trimmed = notes?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
