import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/tasks/task_response.dart';
import 'package:employee_management/features/data/models/tasks/task_history_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class TaskRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  TaskRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<TaskResponse>> fetchTasks({required String startDate}) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);

    return await _networkClient.get<TaskResponse>(
      "task/task?start_date=$startDate",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => TaskResponse.fromJson(json),
    );
  }


  Future<NetworkResult<TaskHistoryResponse>> fetchTaskHistory(
    String userId, {
    String? startDate,
    String? endDate,
  }) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    
    // Build query parameters
    final params = <String>['users=$userId'];
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    
    final queryString = params.join('&');
    final url = "task/evening-task-list/?$queryString";
    
    return await _networkClient.get<TaskHistoryResponse>(
      url,
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => TaskHistoryResponse.fromJson(json),
    );
  }
}
