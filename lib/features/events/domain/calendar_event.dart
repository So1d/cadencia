import '../../../core/utils/id.dart';

/// Um compromisso da agenda.
///
/// Imutável: quando algo muda, o controlador cria uma cópia com [copyWith].
/// Isso deixa a regra de negócio previsível e os testes simples.
class CalendarEvent {
  CalendarEvent({
    String? id,
    required this.title,
    required this.start,
    this.end,
    this.notes,
    this.allDay = false,
  }) : id = id ?? newId();

  final String id;
  final String title;

  /// Início do evento.
  final DateTime start;

  /// Fim do evento (opcional — eventos de dia inteiro normalmente não têm).
  final DateTime? end;

  final String? notes;
  final bool allDay;

  CalendarEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
    String? notes,
    bool clearNotes = false,
    bool? allDay,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
      notes: clearNotes ? null : (notes ?? this.notes),
      allDay: allDay ?? this.allDay,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'notes': notes,
        'all_day': allDay,
      };

  factory CalendarEvent.fromJson(Map<String, Object?> json) {
    final start = DateTime.tryParse(json['start'] as String? ?? '');
    final end = DateTime.tryParse(json['end'] as String? ?? '');
    return CalendarEvent(
      id: json['id'] as String?,
      title: (json['title'] as String?) ?? 'Evento sem título',
      start: start ?? DateTime.now(),
      end: end,
      notes: json['notes'] as String?,
      allDay: json['all_day'] == true,
    );
  }

  @override
  bool operator ==(Object other) => other is CalendarEvent && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CalendarEvent($id, $title, $start)';
}
