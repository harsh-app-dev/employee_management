class LeaveApprovalRequest {
  final String id;
  final String requestedBy;
  final int leaveType;
  final String fromDate;
  final String toDate;
  final int? fromTime; // Some responses have int, some null
  final int? toTime;   // Same here
  final String reason;
  final String? attachment;
  final String status;
  final String leaveTypeName;


  LeaveApprovalRequest({
    required this.id,
    required this.requestedBy,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    this.fromTime,
    this.toTime,
    required this.reason,
    this.attachment,
    required this.status,
    required this.leaveTypeName,

  });

  factory LeaveApprovalRequest.fromJson(Map<String, dynamic> json) {
    return LeaveApprovalRequest(
      id: json['id'] ?? '',
      requestedBy: json['requested_by'] ?? '',
      leaveType: json['leave_type'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      fromTime: json['from_time'] != null ? int.tryParse(json['from_time'].toString()) : null,
      toTime: json['to_time'] != null ? int.tryParse(json['to_time'].toString()) : null,
      reason: json['reason'] ?? '',
      attachment: json['attachment'],
      status: json['status'] ?? '',
      leaveTypeName: json['leave_type_name'] ?? '',

    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requested_by': requestedBy,
    'leave_type': leaveType,
    'from_date': fromDate,
    'to_date': toDate,
    'from_time': fromTime,
    'to_time': toTime,
    'reason': reason,
    'attachment': attachment,
    'status': status,
    'leave_type_name': leaveTypeName,

  };
}
