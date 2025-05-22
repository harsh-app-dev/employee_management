import 'package:employee_management/core/network/client/network_client.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/login_request.dart';
import 'package:employee_management/features/data/models/login_response.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthRepository {
  final NetworkClient _networkClient;

  AuthRepository(this._networkClient);

  Future<NetworkResult<LoginResponse>> login(
    String email,
    String password,
  ) async {
    return await _networkClient.post<LoginResponse>(
      'login/',
      body: LoginRequest(
        email: email, password: password
      ).toJson(),
      parser: (json) => LoginResponse.fromJson(json),
    );
  }
}
