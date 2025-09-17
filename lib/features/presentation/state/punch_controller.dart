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
import 'package:geolocator/geolocator.dart';
import 'dart:io';

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

  Future<void> punchInOut(String type, {File? punchPhoto}) async {
    punchInOutApiState.value = ApiState.loading();
    try {
      String? latLong;
      if (type == 'punch_in' || type == 'punch_out') {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latLong = "${position.latitude},${position.longitude}";
      }

      NetworkResult<PunchInOutResponse> result;

      if (punchPhoto != null) {
        result = await _punchUseCase.callWithPhoto(
          type,
          type == 'punch_in' ? latLong : null,
          type == 'punch_out' ? latLong : null,
          punchPhoto,
        );
      } else {
        final request = PunchInOutRequest(
          type: type,
          punchedInLatLong: type == 'punch_in' ? latLong : null,
          punchedOutLatLong: type == 'punch_out' ? latLong : null,
        );
        result = await _punchUseCase(request);
      }

      if (result is NetworkSuccess<PunchInOutResponse>) {
        punchInOutApiState.value = ApiState.success(result.data);
        if (type == 'punch_in') {
          isPunchedIn.value = true;
          isPunchedOut.value = false;
        } else if (type == 'punch_out') {
          isPunchedOut.value = true;
        }
      } else if (result is NetworkError<PunchInOutResponse>) {
        punchInOutApiState.value = ApiState.error(result.message);
      } else {
        punchInOutApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      punchInOutApiState.value = ApiState.error(
        "Check internet connection or app permissions.",
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
        } else if (result is NetworkError<PunchStateResponse>) {
          punchStateApiState.value = ApiState.error(result.message);
        } else {
          punchStateApiState.value = ApiState.error("Unknown error occurred");
        }
      } catch (e) {
        punchStateApiState.value = ApiState.error(
          "Check internet connection or app permissions.",
        );
      }
    }

    void clearState() {
      punchInOutApiState.value = ApiState.initial();
      punchStateApiState.value = ApiState.initial();
    }
  }
