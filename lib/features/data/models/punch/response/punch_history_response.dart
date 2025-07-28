class PunchHistoryResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<PunchEntry> results;

  PunchHistoryResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PunchHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PunchHistoryResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>?)?.map((e) => PunchEntry.fromJson(e)).toList() ?? [],
    );
  }
}

class PunchEntry {
  final int id;
  final String date;
  final String employee;
  final String? punchIn;
  final String? punchOut;
  final String? punchInPhoto;
  final String? punchOutPhoto;
  final String? punchedInLatLong;
  final String? punchedOutLatLong;
  final List<BreakEntry> breaks;
  final String totalWorkTime;
  final String totalBreakTime;

  PunchEntry({
    required this.id,
    required this.date,
    required this.employee,
    this.punchIn,
    this.punchOut,
    this.punchInPhoto,
    this.punchOutPhoto,
    this.punchedInLatLong,
    this.punchedOutLatLong,
    required this.breaks,
    required this.totalWorkTime,
    required this.totalBreakTime,
  });

  factory PunchEntry.fromJson(Map<String, dynamic> json) {
    return PunchEntry(
      id: json['id'],
      date: json['date'] ?? '',
      employee: json['employee'] ?? '',
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      punchInPhoto: json['punch_in_photo'],
      punchOutPhoto: json['punch_out_photo'],
      punchedInLatLong: json['punched_in_lat_long'],
      punchedOutLatLong: json['punched_out_lat_long'],
      breaks: (json['breaks'] as List<dynamic>?)?.map((e) => BreakEntry.fromJson(e)).toList() ?? [],
      totalWorkTime: json['total_work_time'] ?? '',
      totalBreakTime: json['total_break_time'] ?? '',
    );
  }
}

class BreakEntry {
  final int id;
  final String? breakStart;
  final String? breakOver;
  final int? attendance;

  BreakEntry({
    required this.id,
    this.breakStart,
    this.breakOver,
    this.attendance,
  });

  factory BreakEntry.fromJson(Map<String, dynamic> json) {
    return BreakEntry(
      id: json['id'],
      breakStart: json['break_start'],
      breakOver: json['break_over'],
      attendance: json['attendance'],
    );
  }
}
