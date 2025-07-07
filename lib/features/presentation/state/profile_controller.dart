import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/profile/profile_response.dart';
import 'package:employee_management/features/data/models/floor/profile_dao.dart';
import 'package:employee_management/features/data/models/floor/profile_data.dart';
import 'package:employee_management/features/domain/use_cases/logout_use_case.dart';
import 'package:employee_management/features/domain/use_cases/profile_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileController {
  final ProfileUseCase _profileUseCase;
  final LogoutUseCase _logoutUseCase;
  final ProfileDao _profileDao;

  ProfileController(
    this._profileUseCase,
    this._logoutUseCase,
    this._profileDao,
  );

  final ValueNotifier<ApiState<Profile>> profileApiState = ValueNotifier(
    ApiState.initial(),
  );
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  String currentProfileId = '';

  Future<void> fetchProfile() async {
    profileApiState.value = ApiState.loading();
    try {
      Profile? profile;
      if (currentProfileId.isNotEmpty) {
        profile = await _profileDao.getProfile(currentProfileId);
      } else {
        final profiles = await _profileDao.getAllProfiles();
        profile = profiles.isNotEmpty ? profiles.first : null;
      }
      if (profile != null) {
        profileApiState.value = ApiState.success(profile);
      } else {
        profileApiState.value = ApiState.error("No profile found in database");
      }
    } catch (e) {
      profileApiState.value = ApiState.error(
        "Something went wrong. Please try again.",
      );
    }
  }

  Future<void> fetchAndSaveProfile() async {
    profileApiState.value = ApiState.loading();
    try {
      final result = await _profileUseCase();
      if (result is NetworkSuccess<ProfileResponse>) {
        final profile = _convertResponseToProfile(result.data);
        try {
          await _profileDao.insertProfile(profile);
          debugPrint('Profile inserted successfully');
        } catch (insertError, insertStack) {
          debugPrint('Error during insertProfile: $insertError\n$insertStack');
        }
        profileApiState.value = ApiState.success(profile);
        currentProfileId = profile.id;
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

  Profile _convertResponseToProfile(ProfileResponse response) {
    return Profile(
      id: response.id ?? '',
      first_name: (response.firstName?.isNotEmpty ?? false)
          ? response.firstName!
          : 'No Name',
      last_name: (response.lastName?.isNotEmpty ?? false)
          ? response.lastName!
          : 'No Last Name',
      email: (response.email?.isNotEmpty ?? false)
          ? response.email!
          : 'noemail@example.com',
      dob: (response.dateOfBirth?.isNotEmpty ?? false)
          ? response.dateOfBirth!
          : '1990-01-01',
      phoneNo: (response.contactNumber?.isNotEmpty ?? false)
          ? response.contactNumber!
          : '1234567890',
      designation: (response.designation?.toString().isNotEmpty ?? false)
          ? response.designation.toString()
          : 'Android Developer',
      organization: (response.organization?.isNotEmpty ?? false)
          ? response.organization!
          : 'SparkBrains',
      employee_active: (response.employeeActive?.isNotEmpty ?? false)
          ? response.employeeActive!
          : 'Inactive',
    );
  }

  Future<void> logout() async {
    await _logoutUseCase();
    _profileDao.clearProfile();
  }

  ProfileDao get profileDao => _profileDao;
}
