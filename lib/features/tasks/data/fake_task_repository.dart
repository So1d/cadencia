import '../domain/repositories/task_repository.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';

/// Repositório **falso**, com atraso simulado.
///
/// Permite desenvolver a interface e exercitar os quatro estados antes de
/// existir a fonte real — e escrever testes determinísticos sem tocar no
/// armazenamento do aparelho.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    List<Task>? seed,
    this.latency = const Duration(milliseconds: 500),
    this.shouldFail = false,
    this.failuresRemaining = 0,
  }) : _tasks = [...?seed];

  /// Tempo simulado de "busca" — deixa o estado de carregamento visível.
  final Duration latency;

  /// Quando verdadeiro, [fetchAll] **sempre** lança exceção.
  final bool shouldFail;

  /// Falhas restantes antes de começar a funcionar.
  ///
  /// É o que permite mostrar o erro **com recuperação real**: a primeira
  /// carga falha e o "Tentar novamente" funciona.
  int failuresRemaining;

  final List<Task> _tasks;

  /// Semente de exemplo para o modo demonstração.
  static List<Task> get demo {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      Task(
        title: 'Revisar o planejamento da semana',
        priority: TaskPriority.high,
        dueDate: today,
      ),
      Task(
        title: 'Enviar o relatório mensal',
        dueDate: today,
        priority: TaskPriority.medium,
      ),
      Task(title: 'Estudar Flutter por 30 minutos'),
      Task(
        title: 'Comprar presente da Ana',
        dueDate: today.add(const Duration(days: 3)),
      ),
      Task(
        title: 'Agendar manutenção do carro',
        done: true,
        priority: TaskPriority.low,
      ),
    ];
  }

  @override
  Future<List<Task>> fetchAll() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw Exception('Falha simulada ao carregar as tarefas.');
    }
    if (shouldFail) {
      throw Exception('Falha simulada ao carregar as tarefas.');
    }
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> saveAll(List<Task> tasks) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _tasks
      ..clear()
      ..addAll(tasks);
  }
}
