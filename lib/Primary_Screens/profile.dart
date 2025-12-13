import 'package:final_project/AuthScreens/change_pwd.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Widget _buildDarkModeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.currentTheme == darkMode;

    return _modernSettingsCard(
      icon: Icons.dark_mode_outlined,
      title: "Dark Mode",
      trailing: Switch(
        value: isDarkMode,
        onChanged: (_) => themeProvider.toggleTheme(),
        activeThumbColor: accentColor,
      ),
      onTap: () => themeProvider.toggleTheme(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          "assets/image/icon 2.png",
                          fit: BoxFit.cover,
                          width: 85,
                          height: 85,
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // Name & Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Shady_o.a",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Kisii, Kenya",
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ------------- SETTINGS TITLE -----------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ------------- SETTINGS ITEMS -----------------
              _buildDarkModeToggle(),

              _modernSettingsCard(
                icon: Icons.lock_outline_rounded,
                title: "Change Password",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
                },
              ),

              _modernSettingsCard(
                icon: Icons.info_outline,
                title: "About Penny Wise",
                onTap: () {
                  showCustomToast(
                    context: context,
                    message:
                        "Penny Wise helps you track your expenses, budgets, and financial goals.",
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
                    MaterialPageRoute(
                      builder: (_) => Login(showSignupPage: () {}),
                    ),
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
