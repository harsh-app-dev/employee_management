class LeaveBalance {
  final String leaveType;
  final int total;
  final int used;
  final int remaining;
  final int carryForward;

  LeaveBalance({
    required this.leaveType,
    required this.total,
    required this.used,
    required this.remaining,
    required this.carryForward,
  });
}