import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/data/repositories/task_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class TaskUseCase {
  final TaskRepository _taskRepository;

  TaskUseCase(this._taskRepository);

  Future<NetworkResult<TaskResponse>> call() {
    return _taskRepository.fetchTasks();
  }
}