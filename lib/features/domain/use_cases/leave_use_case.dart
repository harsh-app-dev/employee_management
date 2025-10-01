import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';
import '../../data/models/leave/leave_type.dart';

class LeaveUseCase {
  final LeaveRepository leaveRepository;

  LeaveUseCase(this.leaveRepository);

  // Update return type to match repository
  Future<NetworkResult<List<LeaveType>>> fetchLeaveTypes() {
    return leaveRepository.fetchLeaveTypes();
  }
}
