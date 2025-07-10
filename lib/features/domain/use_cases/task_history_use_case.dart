import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';
import 'package:employee_management/features/data/repositories/task_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class TaskHistoryUseCase {
  final TaskRepository _taskRepository;

  TaskHistoryUseCase(this._taskRepository);

  Future<NetworkResult<TaskHistoryResponse>> call(
    String userId, {
    String? startDate,
    String? endDate,
  }) {
    return _taskRepository.fetchTaskHistory(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
  }
} 