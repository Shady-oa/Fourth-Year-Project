// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Note: Assuming AuthService handles the password change logic

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Controllers for the three password fields
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // Helper method to build text fields based on your existing design
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: radiusMedium),
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        filled: true,
      ),
    );
  }

  //confirm
  Future<void> _handleChangePassword() async {
    User user = FirebaseAuth.instance.currentUser!;
    String email = user.email!;
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      showCustomToast(
        context: context,
        message: "Please fill in all fields!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _confirmNewPasswordController.clear();
      _newPasswordController.clear();
      _currentPasswordController.clear();
      showCustomToast(
        context: context,
        message: "New passwords do not match!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );

      return;
    }

    if (newPassword.length < 6) {
      // Firebase minimum password length
      showCustomToast(
        context: context,
        message: "New password must be at least 6 characters.",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );

      await user.updatePassword(newPassword);
      showCustomToast(
        context: context,
        message: 'Password Changed Successfully!',
        backgroundColor: accentColor,
        icon: Icons.check_circle_outline_rounded,
      );

      Navigator.pop(context);
    } catch (e) {
      showCustomToast(
        context: context,
        message: "Current password is incorrect!",
        backgroundColor: errorColor,
        icon: Icons.error_outline_rounded,
      );
      _confirmNewPasswordController.clear();
      _newPasswordController.clear();
      _currentPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen,

      body: Column(
        children: [
          // Header Text
          Container(
            alignment: Alignment.center,
            height: 150,
            child: Row(
              children: [
                CustomBackButton(),
                Text(
                  "Change Password",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: paddingAllMedium,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: topOnly,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    formLogo,

                    sizedBoxHeightLarge,
                    Text(
                      'Reset Your Password',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    sizedBoxHeightSmall,

                    // Current Password Field
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      hintText: 'Current Password',
                    ),

                    sizedBoxHeightSmall,

                    // New Password Field
                    _buildPasswordField(
                      controller: _newPasswordController,
                      hintText: 'New Password',
                    ),

                    sizedBoxHeightSmall,

                    // Confirm New Password Field
                    _buildPasswordField(
                      controller: _confirmNewPasswordController,
                      hintText: 'Confirm New Password',
                    ),

                    sizedBoxHeightXLarge,

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: radiusMedium,
                          ),
                        ),
                        onPressed: _handleChangePassword,
                        child: Text(
                          'Save New Password',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface, // Using Theme.of(context).colorScheme.onSurface for contrast
                          ),
                        ),
                      ),
                    ),
                    sizedBoxHeightLarge,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
