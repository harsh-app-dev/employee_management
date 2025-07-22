class LeaveType {
  final int id;
  final String name;

  LeaveType({required this.id, required this.name});

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(id: json['id'], name: json['name']);
  }
}

class HalfDayOption {
  final String code;
  final String name;

  HalfDayOption({required this.code, required this.name});

  factory HalfDayOption.fromJson(Map<String, dynamic> json) {
    return HalfDayOption(code: json['code'], name: json['name']);
  }
}
