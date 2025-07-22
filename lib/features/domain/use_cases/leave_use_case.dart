import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/repositories/leave_repository.dart';

class LeaveUseCase {
  final LeaveRepository leaveRepository;

  LeaveUseCase(this.leaveRepository);

  Future<NetworkResult<Map<String, dynamic>>> fetchLeaveTypes() {
    return leaveRepository.fetchLeaveTypes();
  }

  // Add more leave-related methods as needed
}
