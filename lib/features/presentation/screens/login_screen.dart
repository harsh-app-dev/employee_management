import 'package:employee_management/core/di/injectable_module.dart';
import 'package:employee_management/core/utils/util.dart';
import 'package:employee_management/features/presentation/state/login_controller.dart';
import 'package:flutter/material.dart';

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
            valueListenable: _controller.loginApiState,
            builder: (context, loginApiState, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(themedAsset(context, 'logo.png')),
                  ),
                  const SizedBox(height: 24),
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
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                errorText: emailError,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<String?>(
                          valueListenable: _controller.passwordError,
                          builder: (context, passwordError, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: _controller.isPasswordVisible,
                              builder: (context, isPasswordVisible, _) {
                                return TextFormField(
                                  controller: _passwordController,
                                  keyboardType: TextInputType.visiblePassword,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    errorText: passwordError,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: _controller.togglePasswordVisibility,
                                    ),
                                  ),
                                  obscureText: !isPasswordVisible,
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: loginApiState.isLoading
                                ? null
                                : () async {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              await _controller.login(email, password);

                              final error = _controller.submissionError.value;
                              if (error != null) {
                                showGlobalSnackBar(error);
                              } else if (_controller.loginApiState.value.isSuccess) {
                                // Success logic here
                              }
                            },
                            child: loginApiState.isLoading
                                ? const SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                              ),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(fontSize: 24),
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
    );
  }
}