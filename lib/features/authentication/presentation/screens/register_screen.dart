import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/auth_button.dart';
import 'package:smart_farm/features/authentication/presentation/widgets/textform.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child:  Padding(
            padding: EdgeInsets.all(AppSizes.paddingL(context)),
            child: Column(
              children: [
                CustomTextFormField(
                  hintText: "Enter name",
                  prefixIcon: Icon(Icons.email),
                  iconColor: AppColors.primaryText,
                ),
                SizedBox(height: AppSizes.spaceS(context)),

                CustomTextFormField(
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
                  iconColor: AppColors.primaryText,
                ),
                SizedBox(height: AppSizes.spaceS(context)),

                CustomTextFormField(
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.password_sharp),
                  iconColor: AppColors.primaryText,
                ),
                SizedBox(height: AppSizes.spaceS(context)),
                CustomTextFormField(
                  hintText: 'Confirm Password',
                  prefixIcon: Icon(Icons.password),
                  iconColor: AppColors.primaryText,
                ),
                SizedBox(height: AppSizes.spaceM(context)),
                //instructions
                Column(
                  children: [
                    signup_info(
                      text: ('At least 8 characters'),
                      context: context,
                    ),
                    SizedBox(height: AppSizes.spaceXS(context)),
                    signup_info(text: ('At least 1 number'), context: context),
                    SizedBox(height: AppSizes.spaceXS(context)),

                    signup_info(
                      text: ('both upper and lowercase letters'),
                      context: context,
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceXL(context)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_box_outline_blank),
                    Expanded(
                      child: Text(
                        'By agreeing to the terms and conditions, you are entering into a legally binding contract with poultriz farm-agent',
                        style: AppFonts.text10normal(
                          context,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceM(context)),
                authButton(
                  text: 'Sign Up',
                  color: AppColors.primaryGreen
                ),
              ],
            ),
          ));
        },
      ),
    );
  }
}

Widget signup_info({required String text, required BuildContext context}) {
  return Row(
    children: [
      Icon(Icons.check_box_rounded, color: Colors.grey),
      SizedBox(width: AppSizes.spaceXS(context)),
      Text(text, style: AppFonts.text12normal(color: AppColors.primaryText, context)),
    ],
  );
}
