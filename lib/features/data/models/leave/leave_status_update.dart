class LeaveStatusUpdate {
  final String action;   // "Approved" or "Rejected"
  final String comments; // optional or mandatory based on your API

  LeaveStatusUpdate({
    required this.action,
    required this.comments,
  });

  factory LeaveStatusUpdate.fromJson(Map<String, dynamic> json) {
    return LeaveStatusUpdate(
      action: json['action'] ?? '',
      comments: json['comments'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'comments': comments,
    };
  }
}
