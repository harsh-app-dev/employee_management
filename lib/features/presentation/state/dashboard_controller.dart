import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/punch_response.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/domain/use_cases/task_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardController {
  final TaskUseCase _taskUseCase;

  DashboardController(this._taskUseCase);

  final ValueNotifier<ApiState<TaskResponse>> tasksApiState = ValueNotifier(
    ApiState.initial(),
  );

  Future<void> fetchTasks() async {
    tasksApiState.value = ApiState.loading();

    try {
      final result = await _taskUseCase();

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

  void clearState() {
    tasksApiState.value = ApiState.initial();
  }
}
