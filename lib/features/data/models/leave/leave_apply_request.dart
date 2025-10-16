import 'dart:io';

class LeaveApplyRequest {
  final int leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> managers;
  final String hr;
  final String reason;
  final File? attachment;
  final String? fromTime; // "HH:mm" or null
  final String? toTime;   // "HH:mm" or null

  LeaveApplyRequest({
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.managers,
    required this.hr,
    required this.reason,
    this.attachment,
    this.fromTime,
    this.toTime,
  });

  Map<String, dynamic> toJson() {
    return {
      "leave_type": leaveType,
      "from_date": fromDate.toIso8601String().split('T').first,
      "to_date": toDate.toIso8601String().split('T').first,
      "managers": managers,
      "hr": hr,
      "reason": reason,
      "from_time": fromTime,
      "to_time": toTime,
      "attachment": attachment?.path,
      "status": "Pending", // default as in Swagger example
    };
  }
}
