import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/repositories/punch_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchInOutUseCase {
  final PunchRepository _punchRepository;

  PunchInOutUseCase(this._punchRepository);

  Future<NetworkResult<PunchInOutResponse>> call(PunchInOutRequest punchInOutRequest) async {
    return await _punchRepository.punchInOut(punchInOutRequest);
  }
}
