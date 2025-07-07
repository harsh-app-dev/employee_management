class PunchHistoryResponse {
  final int id;
  final String date;
  final String? punchIn;
  final String? punchOut;
  final bool isPunchedIn;
  final bool isPunchedOut;
  final String employee;
  final String? punchInLocation;
  final String? punchOutLocation;

  PunchHistoryResponse({
    required this.id,
    required this.date,
    this.punchIn,
    this.punchOut,
    required this.isPunchedIn,
    required this.isPunchedOut,
    required this.employee,
    this.punchInLocation,
    this.punchOutLocation,
  });

  factory PunchHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PunchHistoryResponse(
      id: json['id'],
      date: json['date'],
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      isPunchedIn: json['is_punched_in'] ?? false,
      isPunchedOut: json['is_punched_out'] ?? false,
      employee: json['employee'],
      punchInLocation: json['punched_in_lat_long'],
      punchOutLocation: json['punched_out_lat_long'],
    );
  }
}
