class LeaveBalance {
  final String leaveBalance;
  final int shortLeave;

  LeaveBalance({
    required this.leaveBalance,
    required this.shortLeave,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveBalance: json['leave_balance'] as String? ?? '0.00',
      shortLeave: json['short_leave'] as int? ?? 0,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'leave_balance': leaveBalance,
      'short_leave': shortLeave,
    };
  }
}
