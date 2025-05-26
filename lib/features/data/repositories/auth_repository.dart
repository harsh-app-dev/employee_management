import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/storage/local_storage.dart';
import 'package:employee_management/core/storage/shared_preference_keys.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/login/login_request.dart';
import 'package:employee_management/features/data/models/login/login_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthRepository {
  final NetworkClient _networkClient;
  final LocalStorage _localStorage;

  AuthRepository(this._networkClient, this._localStorage);

  Future<NetworkResult<LoginResponse>> login(
    String email,
    String password,
  ) async {
    final result = await _networkClient.post<LoginResponse>(
      'login/',
      body: LoginRequest(email: email, password: password),
      parser: (json) => LoginResponse.fromJson(json),
    );

    if (result is NetworkSuccess<LoginResponse>) {
      await _localStorage.setString(SharedPreferenceKeys.userDataKey, result.data.toString());
      await _localStorage.setString(SharedPreferenceKeys.tokenKey, result.data.access!);
      await _localStorage.setBool(SharedPreferenceKeys.loggedInKey, true);
    }

    return result;
  }
}
