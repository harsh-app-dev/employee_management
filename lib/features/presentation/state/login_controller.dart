import 'package:employee_management/core/api/api_state.dart';
import 'package:employee_management/core/utils/network_result.dart';
import 'package:employee_management/features/data/models/login/login_response.dart';
import 'package:employee_management/features/domain/use_cases/login_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginController {
  final LoginUseCase _loginUseCase;

  LoginController(this._loginUseCase);

  final ValueNotifier<ApiState<bool>> loginApiState =
  ValueNotifier(ApiState.initial());
  final ValueNotifier<String?> emailError = ValueNotifier(null);
  final ValueNotifier<String?> passwordError = ValueNotifier(null);
  final ValueNotifier<String?> submissionError = ValueNotifier(null);
  final ValueNotifier<bool> isPasswordVisible = ValueNotifier(false);

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  bool _validateInputs(String email, String password) {
    emailError.value = null;
    passwordError.value = null;
    submissionError.value = null;
    bool isValid = true;

    if (email.isEmpty) {
      emailError.value = 'Please enter your email';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError.value = 'Please enter your password';
      isValid = false;
    }
    return isValid;
  }

  Future<void> login(String email, String password) async {
    if (!_validateInputs(email, password)) {
      loginApiState.value = ApiState.initial();
      return;
    }

    loginApiState.value = ApiState.loading();
    submissionError.value = null;

    try {
      final result = await _loginUseCase(email, password);

      if (result is NetworkSuccess<LoginResponse>) {
        loginApiState.value = ApiState.success(true);
      } else if (result is NetworkError<LoginResponse>) {
        final errorMsg = result.message;
        loginApiState.value = ApiState.error(errorMsg);
        submissionError.value = errorMsg;
      } else {
        final errorMsg = "Unknown error occurred";
        loginApiState.value = ApiState.error(errorMsg);
        submissionError.value = errorMsg;
      }
    } catch (e) {
      final errorMsg = "Something went wrong. Please try again.";
      loginApiState.value = ApiState.error(errorMsg);
      submissionError.value = errorMsg;
    }
  }

  void clearEmailError() {
    emailError.value = null;
  }

  void clearPasswordError() {
    passwordError.value = null;
  }

  void clearAllErrors() {
    emailError.value = null;
    passwordError.value = null;
    submissionError.value = null;
    loginApiState.value = ApiState.initial();
  }
}