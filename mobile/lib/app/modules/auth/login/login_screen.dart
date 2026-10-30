import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      init: LoginController(),
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.login, style: AppTextStyles.heading),
                  SizedBox(height: 32.h),
                  CustomTextField(
                    controller: controller.emailController,
                    label: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: controller.passwordController,
                    label: AppStrings.password,
                    obscureText: controller.obscurePassword,
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    label: AppStrings.login,
                    isLoading: controller.isLoading,
                    onPressed: controller.login,
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: Text('Create an account', style: AppTextStyles.body),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
