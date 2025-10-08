class LeaveBalance {
  final String leaveTypeName;
  final String balance;

  LeaveBalance({
    required this.leaveTypeName,
    required this.balance,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveTypeName: json['leave_type_name'] as String? ?? '',
      balance: json['balance'] as String? ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type_name': leaveTypeName,
      'balance': balance,
    };
  }
}
