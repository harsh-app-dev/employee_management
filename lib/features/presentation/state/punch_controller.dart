import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/punch/punch_response.dart';
import 'package:employee_management/features/domain/use_cases/punch_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchController {
  final PunchUseCase _punchUseCase;
  final LocalStorage _localStorage;

  PunchController(this._punchUseCase, this._localStorage);

  final ValueNotifier<ApiState<PunchResponse>?> punchApiState = ValueNotifier(
    ApiState.initial(),
  );
  final ValueNotifier<bool> isPunchedIn = ValueNotifier(false);
  final ValueNotifier<bool> isPunchedOut = ValueNotifier(false);

  Future<void> initPunchStatus() async {
    isPunchedIn.value = _localStorage.getBool(SharedPreferenceKeys.punchInKey) ?? false;
    isPunchedOut.value = _localStorage.getBool(SharedPreferenceKeys.punchOutKey) ?? false;
  }

  Future<void> punchInOut(String punchValue) async {
    punchApiState.value = ApiState.loading();
    try {
      final result = await _punchUseCase();

      if (result is NetworkSuccess<PunchResponse>) {
        punchApiState.value = ApiState.success(result.data);
        if (punchValue.toLowerCase() == 'in') {
          isPunchedIn.value = true;
        } else if (punchValue.toLowerCase() == 'out') {
          isPunchedOut.value = true;
        }
      } else if (result is NetworkError<PunchResponse>) {
        punchApiState.value = ApiState.error(result.message);
      } else {
        punchApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      punchApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }

  void clearState() {
    punchApiState.value = ApiState.initial();
  }
}
