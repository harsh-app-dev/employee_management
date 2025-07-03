import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/data/models/punch/state/PunchStateResponse.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  PunchRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<PunchInOutResponse>> punchInOut(
      PunchInOutRequest punchInOutRequest,
      ) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.post<PunchInOutResponse>(
      "punchinout/attendance/punch/",
      headers: {"Authorization": "Bearer $token"},
      body: punchInOutRequest,
      parser: (json) => PunchInOutResponse.fromJson(json),
    );
  }

  Future<NetworkResult<PunchStateResponse>> getPunchState() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.get<PunchStateResponse>(
      "accounts/user/me/",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => PunchStateResponse.fromJson(json),
    );
  }

  // Fetch punch history with optional pagination and date range
  Future<NetworkResult<List<PunchHistoryResponse>>> getPunchHistory({
    int? page,
    int? pageSize,
    String? startDate,
    String? endDate,
  }) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    String url = "punchinout/attendance/history/";
    List<String> params = [];
    if (page != null) params.add('page=$page');
    if (pageSize != null) params.add('page_size=$pageSize');
    if (startDate != null) params.add('start_date=$startDate');
    if (endDate != null) params.add('end_date=$endDate');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }
    return await _networkClient.get<List<PunchHistoryResponse>>(
      url,
      headers: {"Authorization": "Bearer $token"},
      parser: (json) {
        final List<dynamic> data = json['results'] ?? [];
        return data.map((e) => PunchHistoryResponse.fromJson(e)).toList();
      },
    );
  }
}

