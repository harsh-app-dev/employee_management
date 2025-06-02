import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/data/models/punch/request/punch_in_out_request.dart';
import 'package:employee_management/features/data/models/punch/response/punch_in_out_response.dart';
import 'package:employee_management/features/data/models/punch/state/PunchStateResponse.dart';
import 'package:employee_management/features/domain/use_cases/punch_in_out_use_case.dart';
import 'package:employee_management/features/domain/use_cases/punch_state_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchController {
  final PunchInOutUseCase _punchUseCase;
  final PunchStateUseCase _punchStateUseCase;

  PunchController(this._punchUseCase, this._punchStateUseCase);

  final ValueNotifier<ApiState<PunchInOutResponse>?> punchInOutApiState =
      ValueNotifier(ApiState.initial());
  final ValueNotifier<ApiState<PunchStateResponse>?> punchStateApiState =
      ValueNotifier(ApiState.initial());
  final ValueNotifier<bool> isPunchedIn = ValueNotifier(false);
  final ValueNotifier<bool> isPunchedOut = ValueNotifier(false);
  final ValueNotifier<String> nameInitials = ValueNotifier('');

  bool get hasPunchedInAndOutToday => isPunchedIn.value && isPunchedOut.value;

  Future<void> punchInOut(String punchValue) async {
    punchInOutApiState.value = ApiState.loading();
    try {
      final result = await _punchUseCase(PunchInOutRequest());

      if (result is NetworkSuccess<PunchInOutResponse>) {
        punchInOutApiState.value = ApiState.success(result.data);
        await getPunchState();
      } else if (result is NetworkError<PunchInOutResponse>) {
        punchInOutApiState.value = ApiState.error(result.message);
      } else {
        punchInOutApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      punchInOutApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }

  Future<void> getPunchState() async {
    punchStateApiState.value = ApiState.loading();
    try {
      final result = await _punchStateUseCase();

      if (result is NetworkSuccess<PunchStateResponse>) {
        punchStateApiState.value = ApiState.success(result.data);
        isPunchedIn.value = result.data.isPunchedIn == true;
        isPunchedOut.value = result.data.isPunchedOut == true;
        nameInitials.value = getInitials(result.data.firstName, result.data.lastName);
        // If both are true, user has punched in and out for the day
        // You can use this logic in your UI to hide both buttons:
        // if (isPunchedIn.value && isPunchedOut.value) => hide punch in/out buttons
      } else if (result is NetworkError<PunchStateResponse>) {
        punchStateApiState.value = ApiState.error(result.message);
      } else {
        punchStateApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      punchStateApiState.value = ApiState.error(
        "Something Went Wrong. Please try again.",
      );
    }
  }

  void clearState() {
    punchInOutApiState.value = ApiState.initial();
    punchStateApiState.value = ApiState.initial();
  }
}
