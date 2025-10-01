class LeaveType {
  final int id;
  final String name;
  final String slug;
  final int durationTime;
  final int durationDays;

  LeaveType({
    required this.id,
    required this.name,
    required this.slug,
    required this.durationTime,
    required this.durationDays,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'],
      name: json['name'],
      slug: json['slug'] ?? '',
      durationTime: json['duration_time'] ?? 0,
      durationDays: json['duration_days'] ?? 0,
    );
  }
}
