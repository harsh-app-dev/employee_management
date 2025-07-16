class PunchHistoryResponse {
  final int id;
  final String date;
  final String employee;
  final List<PunchEntry> punches;
  final String totalWorkTime;
  final String totalBreakTime;
  final String? deductionType;

  PunchHistoryResponse({
    required this.id,
    required this.date,
    required this.employee,
    required this.punches,
    required this.totalWorkTime,
    required this.totalBreakTime,
    this.deductionType,
  });

  factory PunchHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PunchHistoryResponse(
      id: json['id'],
      date: json['date'],
      employee: json['employee'],
      punches: (json['punches'] as List<dynamic>?)?.map((e) => PunchEntry.fromJson(e)).toList() ?? [],
      totalWorkTime: json['total_work_time'] ?? '',
      totalBreakTime: json['total_break_time'] ?? '',
      deductionType: json['check_late_and_deduction'] != null ? json['check_late_and_deduction']['deduction_type'] as String? : null,
    );
  }
}

class PunchEntry {
  final int id;
  final String? punchIn;
  final String? punchOut;
  final String? punchInPhoto;
  final String? punchOutPhoto;
  final String? punchedInLatLong;
  final String? punchedOutLatLong;
  final int? attendance;

  PunchEntry({
    required this.id,
    this.punchIn,
    this.punchOut,
    this.punchInPhoto,
    this.punchOutPhoto,
    this.punchedInLatLong,
    this.punchedOutLatLong,
    this.attendance,
  });

  factory PunchEntry.fromJson(Map<String, dynamic> json) {
    return PunchEntry(
      id: json['id'],
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      punchInPhoto: json['punch_in_photo'],
      punchOutPhoto: json['punch_out_photo'],
      punchedInLatLong: json['punched_in_lat_long'],
      punchedOutLatLong: json['punched_out_lat_long'],
      attendance: json['attendance'],
    );
  }
}
