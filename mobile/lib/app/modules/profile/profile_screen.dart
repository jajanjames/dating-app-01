import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_strings.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(title: Text(AppStrings.profile)),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Center(child: Text('Profile Screen')),
        );
      },
    );
  }
}
