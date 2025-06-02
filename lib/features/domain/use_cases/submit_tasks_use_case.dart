import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_task_request.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_tasks_response.dart';
import 'package:employee_management/features/data/repositories/submit_tasks_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class SubmitTasksUseCase {
  final SubmitTaskRepository _repository;

  SubmitTasksUseCase(this._repository);

  Future<NetworkResult<SubmitTasksResponse>> call(
    SubmitTaskRequest request,
  ) async {
    return await _repository.submitTaskStatus(request);
  }
}
