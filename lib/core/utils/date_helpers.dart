/// Compara dois [DateTime] ignorando hora, minuto e segundo.
///
/// O nome `mesmoDia` (e não `isSameDay`) evita conflito com a função homônima
/// exportada pelo pacote `table_calendar`.
bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Retorna a data sem a componente de hora.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Primeiro dia da semana que contém [d], respeitando a preferência do perfil.
DateTime startOfWeek(DateTime d, {bool mondayFirst = true}) {
  final date = dateOnly(d);
  final offset = mondayFirst ? date.weekday - 1 : date.weekday % 7;
  return date.subtract(Duration(days: offset));
}

/// Rótulo curto de horário para as listas.
String timeLabel(DateTime d, {bool allDay = false}) => allDay
    ? 'Dia inteiro'
    : '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';

/// Saudação de acordo com a hora do dia.
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Bom dia';
  if (now.hour < 18) return 'Boa tarde';
  return 'Boa noite';
}
