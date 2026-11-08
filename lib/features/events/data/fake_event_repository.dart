import '../domain/calendar_event.dart';
import '../domain/repositories/event_repository.dart';

/// Repositório **falso** de eventos, com atraso simulado.
///
/// Usado no modo demonstração e nos testes — para exercitar os quatro estados
/// sem depender do armazenamento do aparelho.
class FakeEventRepository implements EventRepository {
  FakeEventRepository({
    List<CalendarEvent>? seed,
    this.latency = const Duration(milliseconds: 500),
    this.shouldFail = false,
    this.failuresRemaining = 0,
  }) : _events = [...?seed];

  final Duration latency;
  final bool shouldFail;
  int failuresRemaining;
  final List<CalendarEvent> _events;

  /// Semente de exemplo para o modo demonstração.
  static List<CalendarEvent> get demo {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      CalendarEvent(
        title: 'Reunião de planejamento',
        start: DateTime(today.year, today.month, today.day, 9, 30),
        end: DateTime(today.year, today.month, today.day, 10, 15),
        notes: 'Revisar as metas da semana.',
      ),
      CalendarEvent(
        title: 'Consulta',
        start: DateTime(today.year, today.month, today.day, 14),
        end: DateTime(today.year, today.month, today.day, 15),
      ),
      CalendarEvent(
        title: 'Aniversário da Ana',
        start: today.add(const Duration(days: 3)),
        allDay: true,
      ),
    ];
  }

  @override
  Future<List<CalendarEvent>> fetchAll() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw Exception('Falha simulada ao carregar os eventos.');
    }
    if (shouldFail) {
      throw Exception('Falha simulada ao carregar os eventos.');
    }
    return List.unmodifiable(_events);
  }

  @override
  Future<void> saveAll(List<CalendarEvent> events) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _events
      ..clear()
      ..addAll(events);
  }
}
