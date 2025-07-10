import 'package:employee_management/core/configs/strings.dart';
import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/state/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

import '../../../core/widgets/debouncing_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginController _controller;
  final Debouncer _loginDebouncer = Debouncer(delay: Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _controller = getIt<LoginController>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set white background
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 5.h), // Moves everything up
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: ValueListenableBuilder(
                  valueListenable: _controller.loginApiState,
                  builder: (context, loginApiState, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20.h,
                          child: Image.asset(themedAsset(context, 'logo.png')),
                        ),
                        SizedBox(height: 5.h),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              ValueListenableBuilder<String?>(
                                valueListenable: _controller.emailError,
                                builder: (context, emailError, _) {
                                  return TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 16.sp,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: AppStrings.email,
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      errorText: emailError,
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 2.h),
                              ValueListenableBuilder<String?>(
                                valueListenable: _controller.passwordError,
                                builder: (context, passwordError, _) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _controller.isPasswordVisible,
                                    builder: (context, isPasswordVisible, _) {
                                      return TextFormField(
                                        controller: _passwordController,
                                        keyboardType:
                                            TextInputType.visiblePassword,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 16.sp,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: AppStrings.password,
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(12),
                                            ),
                                          ),
                                          errorText: passwordError,
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: _controller
                                                .togglePasswordVisibility,
                                          ),
                                        ),
                                        obscureText: !isPasswordVisible,
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(height: 3.h),
                              SizedBox(
                                height: 7.h,
                                width: 100.w,
                                child: FilledButton(
                                  onPressed: () {
                                    _loginDebouncer.run(() async {
                                      if (_controller.loginApiState.value.isLoading) return;

                                      final email = _emailController.text.trim();
                                      final password = _passwordController.text;

                                      await _controller.login(email, password);

                                      final error = _controller.submissionError.value;
                                      if (error != null) {
                                        showGlobalSnackBar(error);
                                      } else if (_controller.loginApiState.value.isSuccess) {
                                        getIt<GlobalKey<NavigatorState>>()
                                            .currentState
                                            ?.pushReplacementNamed('/dashboard');
                                      }
                                    });
                                  },

                                  child: loginApiState.isLoading
                                      ? SizedBox(
                                          height: 4.h,
                                          width: 4.h,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 4,
                                              ),
                                        )
                                      : Text(
                                          AppStrings.login,
                                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
