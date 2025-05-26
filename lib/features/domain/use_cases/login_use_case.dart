import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/login/login_response.dart';
import 'package:employee_management/features/data/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<NetworkResult<LoginResponse>> call(String email, String password) {
    return _authRepository.login(email, password);
  }
}