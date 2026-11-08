import '../calendar_event.dart';

/// Contrato de acesso aos eventos da agenda.
///
/// O domínio define o **quê**; a camada de dados decide o **como**.
abstract interface class EventRepository {
  /// Carrega todos os eventos. Pode lançar exceção (estado de erro).
  Future<List<CalendarEvent>> fetchAll();

  /// Grava o estado atual da coleção.
  Future<void> saveAll(List<CalendarEvent> events);
}
