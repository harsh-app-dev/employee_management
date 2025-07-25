import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/repositories/punch_repository.dart';
import 'package:injectable/injectable.dart';
import 'dart:io';

@injectable
class PunchInOutUseCase {
  final PunchRepository _punchRepository;

  PunchInOutUseCase(this._punchRepository);

  Future<NetworkResult<PunchInOutResponse>> call(PunchInOutRequest punchInOutRequest) async {
    return await _punchRepository.punchInOut(punchInOutRequest);
  }

  // New method for multipart form data upload
  Future<NetworkResult<PunchInOutResponse>> callWithPhoto(
    String punchType, // 'in' or 'out'
    String? punchedInLatLong,
    String? punchedOutLatLong,
    File? photoFile,
  ) async {
    return await _punchRepository.punchInOutWithPhoto(
      punchType,
      punchedInLatLong,
      punchedOutLatLong,
      photoFile,
    );
  }

  // Break logs use case
  Future<NetworkResult<dynamic>> createBreakLog({
    required String breakStart,
    required String breakOver,
    required int attendanceId,
  }) async {
    return await _punchRepository.createBreakLog(
      breakStart: breakStart,
      breakOver: breakOver,
      attendanceId: attendanceId,
    );
  }
}
