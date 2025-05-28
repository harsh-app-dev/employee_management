import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/features/domain/use_cases/punch_use_case.dart';
import 'package:employee_management/features/data/models/punch/punch_response.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class PunchController {
  final PunchUseCase _punchUseCase;

  PunchController(this._punchUseCase);

  final ValueNotifier<ApiState<PunchResponse>?> punchApiState = ValueNotifier(
    ApiState.initial(),
  );

  Future<void> punchInOut() async {
    punchApiState.value = ApiState.loading();
    try {
      final result = await _punchUseCase();

      if (result is NetworkSuccess<PunchResponse>) {
        punchApiState.value = ApiState.success(result.data);
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
