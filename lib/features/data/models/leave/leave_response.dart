class ManagerDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  ManagerDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ManagerDetails.fromJson(Map<String, dynamic> json) {
    return ManagerDetails(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class UserDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  UserDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}

class LeaveResponse {
  final String id;
  final int leaveType;
  final String leaveTypeName;
  final String? fromTime;
  final String? toTime;
  final String fromDate;
  final String toDate;
  final String appliedDate;
  final List<String> managers;
  final String hr;
  final String reason;
  final String status;
  final String? attachment;
  final List<ManagerDetails> managerDetails;
  final UserDetails userDetails;
  final List<String> managerComment;

  LeaveResponse({
    required this.id,
    required this.leaveType,
    required this.leaveTypeName,
    this.fromTime,
    this.toTime,
    required this.fromDate,
    required this.toDate,
    required this.appliedDate,
    required this.managers,
    required this.hr,
    required this.reason,
    required this.status,
    this.attachment,
    required this.managerDetails,
    required this.userDetails,
    required this.managerComment
  });

  factory LeaveResponse.fromJson(Map<String, dynamic> json) {
    return LeaveResponse(
      id: json['id']?.toString() ?? '',
      leaveType: json['leave_type'] is int
          ? json['leave_type']
          : int.tryParse(json['leave_type']?.toString() ?? '0') ?? 0,
      leaveTypeName: json['leave_type_name']?.toString() ?? '',
      fromTime: json['from_time']?.toString(),
      toTime: json['to_time']?.toString(),
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
      appliedDate: json['applied_date']?.toString() ?? '',
      managers: (json['managers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      hr: json['hr']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      attachment: json['attachment']?.toString(),
      managerDetails: (json['manager_details'] as List<dynamic>? ?? [])
          .map((e) => ManagerDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
      userDetails: UserDetails.fromJson(
          json['user_details'] as Map<String, dynamic>? ?? {}),
      managerComment: (json['manager_comments'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}
