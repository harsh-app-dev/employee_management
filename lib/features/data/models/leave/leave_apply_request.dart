import 'dart:io';

class LeaveApplyRequest {
  final DateTime startDate;
  final DateTime endDate;
  final String hrId;
  final List<String> managerIds;
  final String leaveTypeId;
  final String reason;
  final File? attachment;
  final bool isHalfDay;
  final String? halfDaySession; // 'FH' or 'SH'
  final String? startTime; // "HH:mm"
  final String? endTime; // "HH:mm"

  LeaveApplyRequest({
    required this.startDate,
    required this.endDate,
    required this.hrId,
    required this.managerIds,
    required this.leaveTypeId,
    required this.reason,
    this.attachment,
    this.isHalfDay = false,
    this.halfDaySession,
    this.startTime,
    this.endTime,
  });
} 