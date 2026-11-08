import '../../../core/utils/id.dart';
import 'task_priority.dart';

/// Uma tarefa do Cadência.
///
/// Modelo de domínio puro: não importa Flutter, não sabe de tela nem de
/// armazenamento. Só descreve **o que** uma tarefa é.
class Task {
  Task({
    String? id,
    required this.title,
    this.notes,
    this.dueDate,
    this.done = false,
    this.priority = TaskPriority.medium,
  }) : id = id ?? newId();

  final String id;
  final String title;
  final String? notes;

  /// Data de vencimento (apenas a parte do dia é usada).
  final DateTime? dueDate;
  final bool done;
  final TaskPriority priority;

  Task copyWith({
    String? title,
    String? notes,
    bool clearNotes = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? done,
    TaskPriority? priority,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      done: done ?? this.done,
      priority: priority ?? this.priority,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'due_date': dueDate?.toIso8601String(),
        'done': done,
        'priority': priority.value,
      };

  factory Task.fromJson(Map<String, Object?> json) {
    final dueDate = json['due_date'];
    return Task(
      id: json['id'] as String?,
      title: (json['title'] as String?) ?? 'Tarefa sem título',
      notes: json['notes'] as String?,
      dueDate: dueDate is String ? DateTime.tryParse(dueDate) : null,
      done: json['done'] == true,
      priority: TaskPriority.fromValue(
        json['priority'] is int ? json['priority']! as int : 1,
      ),
    );
  }

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task($id, $title, done: $done)';
}
