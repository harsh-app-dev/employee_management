import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/models/punch/state/PunchStateResponse.dart';
import 'package:employee_management/features/data/repositories/punch_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchStateUseCase {
  final PunchRepository _punchRepository;

  PunchStateUseCase(this._punchRepository);

  Future<NetworkResult<PunchStateResponse>> call() async {
    return await _punchRepository.getPunchState();
  }
}
