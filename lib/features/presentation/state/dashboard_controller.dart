import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_task_request.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_tasks_response.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/domain/use_cases/submit_tasks_use_case.dart';
import 'package:employee_management/features/domain/use_cases/task_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardController {
  final TaskUseCase _taskUseCase;
  final SubmitTasksUseCase _submitTasksUseCase;

  DashboardController(this._taskUseCase, this._submitTasksUseCase);

  final ValueNotifier<ApiState<TaskResponse>> tasksApiState = ValueNotifier(
    ApiState.initial(),
  );

  final ValueNotifier<ApiState<SubmitTasksResponse>> submitTasksApiState =
      ValueNotifier(ApiState.initial());

  String? _lastFetchedDate;


  Future<void> fetchTasks({required String startDate}) async {
    _lastFetchedDate = startDate; // save last used date

    tasksApiState.value = ApiState.loading();

    try {
      final result = await _taskUseCase(startDate);

      if (result is NetworkSuccess<TaskResponse>) {
        tasksApiState.value = ApiState.success(result.data);
      } else if (result is NetworkError<TaskResponse>) {
        tasksApiState.value = ApiState.error(result.message);
      } else {
        tasksApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      tasksApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }


  Future<void> submitTasks(TaskResponse tasks) async {
    submitTasksApiState.value = ApiState.loading();
    try {
      final tasksUUIDs = tasks.data?.map((task) => task.id ?? '').toList();
      final result = await _submitTasksUseCase(
        SubmitTaskRequest(taskIds: tasksUUIDs, status: ''),
      );

      if (result is NetworkSuccess<SubmitTasksResponse>) {
        submitTasksApiState.value = ApiState.success(result.data);
        if (_lastFetchedDate != null) {
          await fetchTasks(startDate: _lastFetchedDate!);
        }
      } else if (result is NetworkError<SubmitTasksResponse>) {
        submitTasksApiState.value = ApiState.error(result.message);
      } else {
        submitTasksApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      submitTasksApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }

  void clearState() {
    tasksApiState.value = ApiState.initial();
    submitTasksApiState.value = ApiState.initial();
  }
}
