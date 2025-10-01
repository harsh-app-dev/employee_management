import 'package:injectable/injectable.dart';

import '../../../core/network/client/network_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/storage/shared_preference_keys.dart';
import '../models/report/attendance_report_response.dart';
import '../../../core/utils/network_result.dart';

@injectable
class AttendanceReportRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  AttendanceReportRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<AttendanceReportResponse>> fetchAttendanceReport(
      {required String date}) async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    final queryParams = '?date=$date';
    return await _networkClient.get<AttendanceReportResponse>(
      "attendence/attendance-report$queryParams",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => AttendanceReportResponse.fromJson(json),
    );
  }
}
