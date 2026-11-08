import 'package:cadencia/features/events/domain/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarEvent', () {
    test('ida e volta por JSON preserva os campos', () {
      final event = CalendarEvent(
        id: 'e1',
        title: 'Consulta',
        start: DateTime(2026, 11, 10, 14),
        end: DateTime(2026, 11, 10, 15),
        notes: 'Levar exames',
      );

      final copy = CalendarEvent.fromJson(event.toJson());

      expect(copy.id, 'e1');
      expect(copy.title, 'Consulta');
      expect(copy.start, DateTime(2026, 11, 10, 14));
      expect(copy.end, DateTime(2026, 11, 10, 15));
      expect(copy.notes, 'Levar exames');
      expect(copy.allDay, isFalse);
    });

    test('evento de dia inteiro não exige fim', () {
      final event = CalendarEvent(
        id: 'e2',
        title: 'Aniversário',
        start: DateTime(2026, 11, 12),
        allDay: true,
      );

      final copy = CalendarEvent.fromJson(event.toJson());

      expect(copy.allDay, isTrue);
      expect(copy.end, isNull);
    });

    test('fromJson não quebra com data inválida', () {
      final event = CalendarEvent.fromJson({
        'title': 'Sem data',
        'start': 'ontem',
      });

      expect(event.title, 'Sem data');
      expect(event.start, isA<DateTime>());
    });

    test('copyWith limpa campos e mantém o id', () {
      final event = CalendarEvent(
        title: 'A',
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 1, 2),
        notes: 'nota',
      );

      final copy = event.copyWith(
        title: 'B',
        clearEnd: true,
        clearNotes: true,
      );

      expect(copy.title, 'B');
      expect(copy.end, isNull);
      expect(copy.notes, isNull);
      expect(copy.id, event.id);
    });
  });
}
