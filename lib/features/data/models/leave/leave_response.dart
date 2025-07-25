import 'package:flutter/material.dart';

class LeaveResponse {
  final String id;
  final DateTimeRange dateRange;
  final String leaveType;
  final String reason;
  final String? attachmentPath;
  final String hr;
  final String teamLead;
  final String status;
  final DateTime appliedDate;
  final String? managerComment;
  final DateTime? processedDate;
  final int totalDays;
  final String? shortLeaveTime;
  final String? halfDayType;
  final bool isNewlyApplied;
  final String leaveTypeName;

  LeaveResponse({
    required this.id,
    required this.dateRange,
    required this.leaveType,
    required this.reason,
    this.attachmentPath,
    required this.hr,
    required this.teamLead,
    this.status = 'Pending',
    required this.appliedDate,
    this.managerComment,
    this.processedDate,
    required this.totalDays,
    this.shortLeaveTime,
    this.halfDayType,
    this.isNewlyApplied = false,
    required this.leaveTypeName,
  });

  LeaveResponse copyWith({
    String? id,
    DateTimeRange? dateRange,
    String? leaveType,
    String? reason,
    String? attachmentPath,
    String? hr,
    String? teamLead,
    String? status,
    DateTime? appliedDate,
    String? managerComment,
    DateTime? processedDate,
    int? totalDays,
    String? shortLeaveTime,
    String? halfDayType,
    bool? isNewlyApplied,
    String? leaveTypeName,
  }) {
    return LeaveResponse(
      id: id ?? this.id,
      dateRange: dateRange ?? this.dateRange,
      leaveType: leaveType ?? this.leaveType,
      reason: reason ?? this.reason,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      hr: hr ?? this.hr,
      teamLead: teamLead ?? this.teamLead,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      managerComment: managerComment ?? this.managerComment,
      processedDate: processedDate ?? this.processedDate,
      totalDays: totalDays ?? this.totalDays,
      shortLeaveTime: shortLeaveTime ?? this.shortLeaveTime,
      halfDayType: halfDayType ?? this.halfDayType,
      isNewlyApplied: isNewlyApplied ?? this.isNewlyApplied,
      leaveTypeName: leaveTypeName ?? this.leaveTypeName,
    );
  }
}
