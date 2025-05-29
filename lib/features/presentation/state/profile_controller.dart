import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/profile/profile_response.dart';
import 'package:employee_management/features/domain/use_cases/logout_use_case.dart';
import 'package:employee_management/features/domain/use_cases/profile_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileController {
  final ProfileUseCase _profileUseCase;
  final LogoutUseCase _logoutUseCase;

  ProfileController(this._profileUseCase, this._logoutUseCase);

  final ValueNotifier<ApiState<ProfileResponse>> profileApiState =
      ValueNotifier(ApiState.initial());
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> fetchProfile() async {
    profileApiState.value = ApiState.loading();
    try {
      final result = await _profileUseCase();
      if (result is NetworkSuccess<ProfileResponse>) {
        profileApiState.value = ApiState.success(result.data);
      } else if (result is NetworkError<ProfileResponse>) {
        profileApiState.value = ApiState.error(result.message);
      } else {
        profileApiState.value = ApiState.error("Unknown error occurred");
      }
    } catch (e) {
      profileApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
  }
}
