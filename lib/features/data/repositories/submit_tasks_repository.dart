import 'dart:convert';

import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_task_request.dart';
import 'package:employee_management/features/data/models/tasks/submit/submit_tasks_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class SubmitTaskRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  SubmitTaskRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<SubmitTasksResponse>> submitTaskStatus(
    SubmitTaskRequest request,
  ) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.post<SubmitTasksResponse>(
      "task/update-status/",
      headers: {"Authorization": "Bearer $token"},
      body: request,
      parser: (json) => SubmitTasksResponse.fromJson(json),
    );
  }
}
