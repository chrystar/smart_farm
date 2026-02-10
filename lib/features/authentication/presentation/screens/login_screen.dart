import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/core/routing/app_router.dart';
import 'package:smart_farm/features/authentication/presentation/provider/auth_provider.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/auth_button.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/textform.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<AuthProvider>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      // Give a moment for state to fully propagate
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Navigate to home screen
        context.go(AppRouter.appRoute);
      }
    } else {
      // Show error snackbar with detailed error
      final authProvider = context.read<AuthProvider>();
      final errorMsg = authProvider.error?.isNotEmpty == true
          ? authProvider.error
          : 'Login failed. Please check your credentials or network.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
              
                  children: [
                    
                    Text(
                      'login to get started with farmagent where you can monitor and manage your farm easily',
                      style: AppFonts.text16normal(
                        context,
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.spaceXL(context)),
                    authButton(
                      icon: const Icon(Icons.apple,
                          size: 20, color: Colors.black),
                      text: 'Login with Apple',
                      color: AppColors.background,
                      textColor: AppColors.primaryText,
                    ),
                    SizedBox(height: AppSizes.spaceS(context)),
                    authButton(
                      icon: const Icon(Icons.g_mobiledata, size: 20),
                      color: AppColors.background,
                      text: 'Login with Google',
                      textColor: AppColors.primaryText,
                    ),
                    SizedBox(height: AppSizes.spaceXL(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(width: 30, height: 2, color: Colors.green),
                        const Text('or continue with email'),
                        Container(width: 30, height: 2, color: Colors.green),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceXL(context)),
                    if (authProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    CustomTextFormField(
                      controller: _emailController,
                      hintText: "Enter Email",
                      prefixIcon: const Icon(Icons.email),
                      iconColor: AppColors.primaryText,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.spaceS(context)),
                    CustomTextFormField(
                      controller: _passwordController,
                      hintText: "Enter password",
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      iconColor: AppColors.primaryText,
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.spaceL(context)),
                    authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : authButton(
                            text: 'Login',
                            color: AppColors.primaryGreen,
                            onPressed: _handleLogin,
                          ),
                    SizedBox(height: AppSizes.spaceL(context)),
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        children: [
                          const TextSpan(
                              text: 'by signing in you agree to our '),
                          TextSpan(
                            text: 'terms and conditions ',
                            style: AppFonts.text12normal(context,
                                color: AppColors.primaryTextColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: 'and '),
                          TextSpan(
                            text: 'privacy policies',
                            style: AppFonts.text12normal(context,
                                color: AppColors.primaryTextColor,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
