import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/punch_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  PunchRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<PunchResponse>> punchInOut() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    return await _networkClient.get<PunchResponse>(
      "punchinout/attendance/punch/",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => PunchResponse.fromJson(json),
    );
  }
}
