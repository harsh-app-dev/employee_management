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
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => PunchEntry.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class PunchEntry {
  final int id;
  final String attendanceDate;
  final String totalWorkHour;
  final String totalBreakHour;

  final PunchIn? punchIn;
  final PunchOut? punchOut;

  PunchEntry({
    required this.id,
    required this.attendanceDate,
    required this.totalWorkHour,
    required this.totalBreakHour,
    this.punchIn,
    this.punchOut,
  });

  factory PunchEntry.fromJson(Map<String, dynamic> json) {
    return PunchEntry(
      id: json['id'],
      attendanceDate: json['attendance_date'] ?? '',
      totalWorkHour: json['total_work_hour']?.toString() ?? '00:00:00',
      totalBreakHour: json['total_break_hour']?.toString() ?? '00:00:00',
      punchIn: json['punch_in'] != null
          ? PunchIn.fromJson(json['punch_in'])
          : null,
      punchOut: json['punch_out'] != null
          ? PunchOut.fromJson(json['punch_out'])
          : null,
    );
  }
}

class PunchIn {
  final int id;
  final String time;
  final String? punchedInLatLong;

  PunchIn({
    required this.id,
    required this.time,
    this.punchedInLatLong,
  });

  factory PunchIn.fromJson(Map<String, dynamic> json) {
    return PunchIn(
      id: json['id'],
      time: json['time'],
      punchedInLatLong: json['punched_in_lat_long'],
    );
  }
}

class PunchOut {
  final int id;
  final String time;
  final String? punchedOutLatLong;

  PunchOut({
    required this.id,
    required this.time,
    this.punchedOutLatLong,
  });

  factory PunchOut.fromJson(Map<String, dynamic> json) {
    return PunchOut(
      id: json['id'],
      time: json['time'],
      punchedOutLatLong: json['punched_out_lat_long'],
    );
  }
}
