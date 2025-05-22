import 'package:flutter/material.dart';
import '../../../core/utils/util.dart';
import '../state/login_controller.dart';
import '../../../../core/di/injectable_module.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final LoginController controller = getIt<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
            valueListenable: controller.loginApiState,
            builder: (context, loginApiState, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(themedAsset(context, 'logo.png')),
                  ),
                  const SizedBox(height: 24),

                  // --- Form ---
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email
                        ValueListenableBuilder<String?>(
                          valueListenable: controller.emailError,
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
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                ),
                                errorText: emailError,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        ValueListenableBuilder<String?>(
                          valueListenable: controller.passwordError,
                          builder: (context, passwordError, _) {
                            return ValueListenableBuilder<bool>(
                              valueListenable: controller.isPasswordVisible,
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
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    errorText: passwordError,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: controller.togglePasswordVisibility,
                                    ),
                                  ),
                                  obscureText: !isPasswordVisible,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: loginApiState.isLoading
                                ? null
                                : () async {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              await controller.login(email, password);

                              final error = controller.submissionError.value;
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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