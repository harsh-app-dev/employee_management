class AttendanceReportResponse {
  final int totalWorkingDays;
  final int presentDays;
  final int leaveDays;
  final int absentDays;
  final List<String> leaveDates;
  final List<String> absentDates;
  final List<dynamic> upcomingLeaves;
  final List<Holiday> upcomingHolidays;

  AttendanceReportResponse({
    required this.totalWorkingDays,
    required this.presentDays,
    required this.leaveDays,
    required this.absentDays,
    required this.leaveDates,
    required this.absentDates,
    required this.upcomingLeaves,
    required this.upcomingHolidays,
  });

  factory AttendanceReportResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceReportResponse(
      totalWorkingDays: json['total_working_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      leaveDays: json['leave_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      leaveDates: List<String>.from(json['leave_dates'] ?? []),
      absentDates: List<String>.from(json['absent_dates'] ?? []),
      upcomingLeaves: json['upcoming_leaves'] ?? [],
      upcomingHolidays: (json['upcoming_holidays'] ?? []).map<Holiday>((h) => Holiday.fromJson(h)).toList(),
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
