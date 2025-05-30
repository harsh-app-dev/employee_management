import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
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
      "accounts/attendance",
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
}
