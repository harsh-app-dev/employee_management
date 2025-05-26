import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/tasks_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class TaskRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  TaskRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<List<TasksResponse>>> fetchTasks() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.get<List<TasksResponse>>(
      "task/task/",
      headers: Map.from({"Authorization": "Bearer $token"}),
      parser: (json) =>
          (json as List).map((e) => TasksResponse.fromJson(e)).toList(),
    );
  }
}
