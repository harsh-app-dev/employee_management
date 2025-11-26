import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/response/attendence_response.dart';
import 'package:employee_management/features/data/models/report/attendance_report_response.dart';
import 'package:employee_management/features/domain/use_cases/attendance_report_use_case.dart';
import 'package:employee_management/features/domain/use_cases/punch_history_use_case.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReportController extends GetxController {
  final PunchHistoryUseCase punchUseCase;
  final AttendanceReportUseCase reportUseCase;

  ReportController({required this.punchUseCase, required this.reportUseCase});

  var reportData = Rxn<AttendanceReportResponse>();
  var isLoading = false.obs;
  var error = RxnString();
  var focusedMonth = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch report data for the current month on init
    fetchReportData(focusedMonth.value);
  }

  /// Called when calendar page is changed
  void onCalenderPageChanged(DateTime focusedDay) {
    focusedMonth.value = DateTime(focusedDay.year, focusedDay.month, 1);
    fetchReportData(focusedMonth.value);
  }

  /// Fetch report data for a specific month
  Future<void> fetchReportData(DateTime month) async {
    isLoading.value = true;
    error.value = null;

    final formattedDate = DateFormat('yyyy-MM-dd').format(month);
    final result = await reportUseCase.call(date: formattedDate);

    if (result is NetworkSuccess<AttendanceReportResponse>) {
      reportData.value = result.data;
    } else if (result is NetworkError) {
      error.value = (result as NetworkError<AttendanceReportResponse>).message;
    }

    isLoading.value = false;
  }

  /// Fetch punch details for a specific day
  Future<AttendanceResponse?> getPunchDetails(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final result = await punchUseCase.callPunchDetail(date: formattedDate);

    if (result is NetworkSuccess<AttendanceResponse>) {
      return result.data;
    }
    return null;
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isLeaveDay(DateTime day, Set<DateTime> approvedLeaveDays) =>
      approvedLeaveDays.any((d) => isSameDay(d, day));

  bool isAbsentDay(DateTime day, List<DateTime> absentDays) =>
      absentDays.any((d) => isSameDay(d, day));

  bool isHoliday(DateTime day, List<DateTime> holidayDays) =>
      holidayDays.any((d) => isSameDay(d, day));

  bool isHalfDay(DateTime day, List<DateTime> halfDays) =>
      halfDays.any((d) => isSameDay(d, day));

  bool isShortLeave(DateTime day, List<DateTime> shortLeaves) =>
      shortLeaves.any((d) => isSameDay(d, day));

  bool isPresentDay(DateTime day, Set<DateTime> presentDays) =>
      presentDays.any((d) => isSameDay(d, day));
}
