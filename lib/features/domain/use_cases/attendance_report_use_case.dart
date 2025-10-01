import 'package:injectable/injectable.dart';
import '../../data/repositories/attendance_report_repository.dart';
import '../../data/models/report/attendance_report_response.dart';
import '../../../core/utils/network_result.dart';

@injectable
class AttendanceReportUseCase {
  final AttendanceReportRepository repository;
  AttendanceReportUseCase(this.repository);

  Future<NetworkResult<AttendanceReportResponse>> call({required String date}) async {
    return await repository.fetchAttendanceReport(date: date);
  }
}
