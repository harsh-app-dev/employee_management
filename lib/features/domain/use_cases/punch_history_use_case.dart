import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/response/punch_history_response.dart';
import 'package:employee_management/features/data/repositories/punch_repository.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/punch/response/attendence_response.dart';

@injectable
class PunchHistoryUseCase {
  final PunchRepository _repo;
  PunchHistoryUseCase(this._repo);

  Future<NetworkResult<PunchHistoryResponse>> call({
    int? page,
    int? pageSize,
    String? startDate,
    String? endDate,
  }) {
    return _repo.getPunchHistory(
      page: page,
      pageSize: pageSize,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<NetworkResult<AttendanceResponse>> callPunchDetail() async {
    return await _repo.getPunchHistoryDetail();
  }
}
