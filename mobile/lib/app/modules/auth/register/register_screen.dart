import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utils/app_strings.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import 'register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RegisterController>(
      init: RegisterController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.register)),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: controller.nameController,
                    label: AppStrings.name,
                  ),
                  SizedBox(height: 16.h),
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
                    label: AppStrings.register,
                    isLoading: controller.isLoading,
                    onPressed: controller.register,
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
