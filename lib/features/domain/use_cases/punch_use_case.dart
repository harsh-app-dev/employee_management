import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/punch_response.dart';
import 'package:employee_management/features/data/repositories/punch_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchUseCase {
  final PunchRepository _punchRepository;

  PunchUseCase(this._punchRepository);

  Future<NetworkResult<PunchResponse>> call() async {
    return await _punchRepository.punchInOut();
  }
}
