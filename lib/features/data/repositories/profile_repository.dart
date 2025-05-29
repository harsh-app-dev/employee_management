import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/profile/profile_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProfileRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  ProfileRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<ProfileResponse>> fetchProfile() async {
    final token = _localStorage.getString(SharedPreferenceKeys.tokenKey);
    final result = await _networkClient.get<ProfileResponse>(
      "accounts/profile/",
      headers: {"Authorization": "Bearer $token"},
      parser: (json) => ProfileResponse.fromJson(json),
    );

    if (result is NetworkSuccess<ProfileResponse>) {
      _localStorage.setJson(
        SharedPreferenceKeys.userProfileKey,
        result.data.toJson(),
      );
    }

    return result;
  }
}
