// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toasty_box.dart';
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

  // --- Password Change Logic Placeholder ---
  Future<void> _handleChangePassword() async {
    User user = FirebaseAuth.instance.currentUser!;
    String email = user.email!;
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showToast('Please fill in all password fields.', errorColor);
      return;
    }

    if (newPassword != confirmPassword) {
      _confirmNewPasswordController.clear();
      _newPasswordController.clear();
      _currentPasswordController.clear();
      _showToast('New passwords do not match.', errorColor);

      return;
    }

    /*if (newPassword.length < 6) {
      // Firebase minimum password length
      _showToast('New password must be at least 6 characters.', errorColor);
      return;
    }*/

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );

      await user.updatePassword(newPassword);
      showCustomToast(
        context: context,
        message: 'Password Changed',
        backgroundColor: accentColor,
        icon: Icons.check_circle_outline,
      );

      Navigator.pop(context);
    } catch (e) {
      _showToast(
        'Failed to change password: Check your current password.',
        errorColor,
      );
      _confirmNewPasswordController.clear();
      _newPasswordController.clear();
      _currentPasswordController.clear();
    }
  }

  // Helper to display a toast message
  void _showToast(String message, Color backgroundColor) {
    ToastService.showToast(
      context,
      backgroundColor: backgroundColor,
      message: message,
      length: ToastLength.medium,
      messageStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.surface,
      ),
    );
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
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_rounded),
                ),
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
