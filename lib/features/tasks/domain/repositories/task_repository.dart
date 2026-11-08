import '../task.dart';

/// Contrato de acesso às tarefas.
///
/// O domínio define o **quê** precisa ser feito; quem decide o **como**
/// (dispositivo, servidor, dado falso) é a camada de dados. Assim as telas
/// não sabem — nem precisam saber — de onde os dados vêm.
abstract interface class TaskRepository {
  /// Carrega todas as tarefas. Pode lançar exceção (estado de erro).
  Future<List<Task>> fetchAll();

  /// Grava o estado atual da coleção.
  Future<void> saveAll(List<Task> tasks);
}
