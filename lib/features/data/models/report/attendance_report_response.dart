class AttendanceReportResponse {
  final double totalWorkingDays;
  final double presentDays;
  final double leaveDays;
  final double absentDays;
  final List<String> leaveDates;
  final List<String> absentDates;
  final List<UpcomingLeave> upcomingLeaves;
  final List<Holiday> upcomingHolidays;
  final List<String> shortLeaveDates;
  final List<String> halfDayLeaveDates;

  AttendanceReportResponse({
    required this.totalWorkingDays,
    required this.presentDays,
    required this.leaveDays,
    required this.absentDays,
    required this.leaveDates,
    required this.absentDates,
    required this.upcomingLeaves,
    required this.upcomingHolidays,
    required this.shortLeaveDates,
    required this.halfDayLeaveDates,
  });

  factory AttendanceReportResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceReportResponse(
      totalWorkingDays: (json['total_working_days'] ?? 0).toDouble(),
      presentDays: (json['present_days'] ?? 0).toDouble(),
      leaveDays: (json['leave_days'] ?? 0).toDouble(),
      absentDays: (json['absent_days'] ?? 0).toDouble(),
      leaveDates: List<String>.from(json['leave_dates'] ?? []),
      absentDates: List<String>.from(json['absent_dates'] ?? []),
      upcomingLeaves: (json['upcoming_leaves'] ?? [])
          .map<UpcomingLeave>((l) => UpcomingLeave.fromJson(l))
          .toList(),
      upcomingHolidays: (json['upcoming_holidays'] ?? [])
          .map<Holiday>((h) => Holiday.fromJson(h))
          .toList(),
      halfDayLeaveDates: List<String>.from(json['half_day_leave_dates'] ?? []),
      shortLeaveDates: List<String>.from(json['short_leave_dates'] ?? []),
    );
  }

}

class UpcomingLeave {
  final String fromDate;
  final String toDate;
  final int days;
  final String leaveType;

  UpcomingLeave({
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.leaveType,
  });

  factory UpcomingLeave.fromJson(Map<String, dynamic> json) {
    return UpcomingLeave(
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      days: json['days'] ?? 0,
      leaveType: json['leave_type'] ?? '',
    );
  }
}

class Holiday {
  final String date;
  final String name;

  Holiday({required this.date, required this.name});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['date'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
