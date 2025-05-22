import 'package:employee_management/core/utils/network_result.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/login_response.dart';
import '../../data/repositories/auth_repository.dart';

@injectable
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<NetworkResult<LoginResponse>> call(String email, String password) {
    return _authRepository.login(email, password);
  }
}