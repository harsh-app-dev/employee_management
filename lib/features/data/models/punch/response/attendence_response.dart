import 'dart:convert';

AttendanceResponse attendanceResponseFromJson(String str) =>
    AttendanceResponse.fromJson(json.decode(str));

String attendanceResponseToJson(AttendanceResponse data) =>
    json.encode(data.toJson());

class AttendanceResponse {
  AttendanceResponse({
    required this.attendances,
  });

  List<Attendance> attendances;

  factory AttendanceResponse.fromJson(dynamic json) {
    var list = json as List;
    List<Attendance> attendanceList =
    list.map((e) => Attendance.fromJson(e)).toList();
    return AttendanceResponse(attendances: attendanceList);
  }

  List<dynamic> toJson() =>
      attendances.map((attendance) => attendance.toJson()).toList();
}

class Attendance {
  Attendance({
    int? id,
    String? attendanceDate,
    String? totalWorkHour,
    String? totalBreakHour,
    List<WorkLog>? workLogs,
  }) {
    _id = id;
    _attendanceDate = attendanceDate;
    _totalWorkHour = totalWorkHour;
    _totalBreakHour = totalBreakHour;
    _workLogs = workLogs;
  }

  int? _id;
  String? _attendanceDate;
  String? _totalWorkHour;
  String? _totalBreakHour;
  List<WorkLog>? _workLogs;

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'],
    attendanceDate: json['attendance_date'],
    totalWorkHour: json['total_work_hour'],
    totalBreakHour: json['total_break_hour'],
    workLogs: json['work_logs'] != null
        ? List<WorkLog>.from(
        json['work_logs'].map((x) => WorkLog.fromJson(x)))
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': _id,
    'attendance_date': _attendanceDate,
    'total_work_hour': _totalWorkHour,
    'total_break_hour': _totalBreakHour,
    'work_logs': _workLogs != null
        ? List<dynamic>.from(_workLogs!.map((x) => x.toJson()))
        : null,
  };

  int? get id => _id;
  String? get attendanceDate => _attendanceDate;
  String? get totalWorkHour => _totalWorkHour;
  String? get totalBreakHour => _totalBreakHour;
  List<WorkLog>? get workLogs => _workLogs;
}

class WorkLog {
  WorkLog({
    int? id,
    String? type,
    String? time,  // Parameter
    String? punchInPhoto,
    String? punchInOutPhoto,
    String? punchedInLatLong,
    String? punchedOutLatLong,
    int? attendance,
    String? employeeId,
  }) {
    _id = id;
    _type = type;
    _time = time;  // Assign to private field, not parameter
    _punchInPhoto = punchInPhoto;
    _punchInOutPhoto = punchInOutPhoto;
    _punchedInLatLong = punchedInLatLong;
    _punchedOutLatLong = punchedOutLatLong;
    _attendance = attendance;
    _employeeId = employeeId;
  }

  int? _id;
  String? _type;
  String? _time;  // Private field
  String? _punchInPhoto;
  String? _punchInOutPhoto;
  String? _punchedInLatLong;
  String? _punchedOutLatLong;
  int? _attendance;
  String? _employeeId;

  factory WorkLog.fromJson(Map<String, dynamic> json) => WorkLog(
    id: json['id'],
    type: json['type'],
    time: json['time'],  // Pass to parameter
    punchInPhoto: json['punch_in_photo'],
    punchInOutPhoto: json['punch_in_out_photo'],
    punchedInLatLong: json['punched_in_lat_long'],
    punchedOutLatLong: json['punched_out_lat_long'],
    attendance: json['attendance'],
    employeeId: json['employee_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': _id,
    'type': _type,
    'time': _time,  // Use private field
    'punch_in_photo': _punchInPhoto,
    'punch_in_out_photo': _punchInOutPhoto,
    'punched_in_lat_long': _punchedInLatLong,
    'punched_out_lat_long': _punchedOutLatLong,
    'attendance': _attendance,
    'employee_id': _employeeId,
  };

  int? get id => _id;
  String? get type => _type;
  String? get time => _time;  // Getter returns private field
  String? get punchInPhoto => _punchInPhoto;
  String? get punchInOutPhoto => _punchInOutPhoto;
  String? get punchedInLatLong => _punchedInLatLong;
  String? get punchedOutLatLong => _punchedOutLatLong;
  int? get attendance => _attendance;
  String? get employeeId => _employeeId;
}