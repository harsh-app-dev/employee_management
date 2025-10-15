class LeaveBalance {
  final String id;
  final String leaveTypeName;
  final String balance;
  final String totalLeaves;

  LeaveBalance({
    required this.id,
    required this.leaveTypeName,
    required this.balance,
    required this.totalLeaves,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] as String? ?? '',
      leaveTypeName: json['leave_type_name'] as String? ?? '',
      balance: json['balance'] as String? ?? '0.00',
      totalLeaves: json['total_leaves'] as String? ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leave_type_name': leaveTypeName,
      'balance': balance,
      'total_leaves': totalLeaves,
    };
  }
}
