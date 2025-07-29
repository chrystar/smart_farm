import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/features/authentication/data/datasourse/auth_remote_datasource.dart';
import 'package:smart_farm/features/authentication/domain/entities/user.dart';
import 'package:smart_farm/features/authentication/presentation/provider/auth_provider.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/auth_button.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/textform.dart';
import 'package:http/http.dart' as http;
import 'package:smart_farm/features/home.dart/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  late final AuthRemoteDataSource _authDataSource;

  @override
  void initState() {
    super.initState();
    _authDataSource = AuthRemoteDataSourceImpl(client: http.Client());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authDataSource.login(
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Create user object from response
      final user = User(
        id: result['user']['id'],
        name: result['user']['name'],
        phoneNumber: result['user']['phoneNumber'],
        token: result['token'],
      );

      // Set auth data in provider
      await context.read<AuthProvider>().setAuthData(
        token: result['token'],
        user: user,
      );
      
      // Navigate to home screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                authButton(
                  icon: Icon(Icons.apple, size: 20, color: Colors.black),
                  text: 'Login with Apple',
                  color: AppColors.background,
                  textColor: AppColors.primaryText,
                ),
                SizedBox(height: AppSizes.spaceS(context)),
                authButton(
                  icon: Icon(Icons.g_mobiledata, size: 20),
                  color: AppColors.background,
                  text: 'Login with Google',
                  textColor: AppColors.primaryText,
                ),

                SizedBox(height: AppSizes.spaceXL(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(width: 30, height: 2, color: Colors.green),
                    Text('or continue with number'),
                    Container(width: 30, height: 2, color: Colors.green),
                  ],
                ),
                SizedBox(height: AppSizes.spaceXL(context)),
                
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                CustomTextFormField(
                  controller: _phoneController,
                  hintText: "Enter Phone Number",
                  prefixIcon: Icon(Icons.phone),
                  iconColor: AppColors.primaryText,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSizes.spaceS(context)),
                CustomTextFormField(
                  controller: _passwordController,
                  hintText: "Enter password",
                  prefixIcon: Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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

                _isLoading
                    ? CircularProgressIndicator()
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
                      TextSpan(text: 'by signing up you agree to '),
                      TextSpan(
                        text: 'our terms and conditions ',
                        style: AppFonts.text12normal(context, color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'and  '),
                      TextSpan(
                        text: 'private policies',
                        style: AppFonts.text12normal(context, color: AppColors.primaryTextColor, fontWeight: FontWeight.bold)
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
  }
}
