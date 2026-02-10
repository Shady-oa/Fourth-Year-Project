import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/AuthScreens/change_pwd.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Note: SharedPreferences import here is optional now since the Provider handles it

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProfileContent();
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent();

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final cloudinary = CloudinaryService(
    backendUrl: 'https://fourth-year-backend.onrender.com',
  );
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  void loadData() async {
    userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .snapshots()
        .listen((snapshots) {
      if (snapshots.exists) {
        final userData = snapshots.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'] ?? '';
          profileImage = userData['profileUrl'] ?? '';
        });
      }
    });
  }

  void pickAndUploadImage() async {
    File? image = await cloudinary.pickImage();
    if (image != null) {
      String? url = await cloudinary.uploadFile(image);
      if (url != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .update({'profileUrl': url});

          showCustomToast(
            context: context,
            message: 'Profile image changed successful!',
            backgroundColor: accentColor,
            icon: Icons.check_circle_outline_rounded,
          );
        } catch (e) {
          showCustomToast(
            context: context,
            message: 'an error occured please try again',
            backgroundColor: errorColor,
            icon: Icons.error,
          );
        }
      } else {
        showCustomToast(
          context: context,
          message: 'Upload failed',
          backgroundColor: errorColor,
          icon: Icons.error,
        );
      }
    }
  }

  Widget _modernSettingsCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: radiusMedium,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: radiusMedium,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: radiusMedium,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ],
        ),
      ),
    );
  }

  Widget buildDarkModeToggle() {
    // listen: true (default) allows the UI to rebuild when the theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determine the state based on which ThemeData is active
    final isDarkMode = themeProvider.currentTheme.brightness == Brightness.dark;

    return _modernSettingsCard(
      icon: Icons.dark_mode_outlined,
      title: "Dark Mode",
      trailing: Switch(
        value: isDarkMode,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeTrackColor: brandGreen.withOpacity(0.4),
        activeThumbColor: brandGreen,
      ),
      onTap: () => themeProvider.toggleTheme(),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: CustomHeader(headerName: "Profile"),
      ),
      body: Padding(
        padding: paddingAllMedium,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------- PROFILE HEADER ------------------
              Container(
                padding: paddingAllLarge,
                decoration: BoxDecoration(
                  borderRadius: radiusLarge,
                  color: brandGreen,
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: (profileImage == null || profileImage!.isEmpty)
                              ? const AssetImage("assets/image/icon.png") as ImageProvider
                              : NetworkImage(profileImage!),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.add_a_photo,
                                size: 16,
                                color: brandGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username ?? 'User',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                "Kisii, Kenya",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),

              buildDarkModeToggle(),

              _modernSettingsCard(
                icon: Icons.lock_outline_rounded,
                title: "Change Password",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                  );
                },
              ),

              _modernSettingsCard(
                icon: Icons.info_outline,
                title: "About Penny Wise",
                onTap: () {
                  showCustomToast(
                    context: context,
                    message: "Penny Wise helps you track your expenses and budgets.",
                    backgroundColor: brandGreen,
                    icon: Icons.info_outline_rounded,
                  );
                },
              ),

              _modernSettingsCard(
                icon: Icons.logout_rounded,
                title: "Logout",
                onTap: () {
                  showCustomToast(
                    context: context,
                    message: "Logged out successfully!",
                    backgroundColor: accentColor,
                    icon: Icons.check_circle_outline_rounded,
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => Login(showSignupPage: () {})),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}