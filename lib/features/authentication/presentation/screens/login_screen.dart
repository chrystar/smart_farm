import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/auth_button.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/textform.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 30),
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
              CustomTextFormField(
                hintText: "Enter Number",
                prefixIcon: Icon(Icons.email),
                iconColor: AppColors.primaryText,
              ),
              SizedBox(height: AppSizes.spaceS(context)),
              CustomTextFormField(
                hintText: "Enter password",
                prefixIcon: Icon(Icons.password),
                suffixIcon: Icon(Icons.remove_red_eye),
                iconColor: AppColors.primaryText,
              ),
              SizedBox(height: AppSizes.spaceL(context)),

              authButton(text: 'Login', color: AppColors.primaryGreen),

              SizedBox(height: AppSizes.spaceL(context),),
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
                    TextSpan(text: 'private policies', style: AppFonts.text12normal(context, color: AppColors.primaryTextColor, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
