import 'package:final_project/AuthScreens/change_pwd.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Primary_Screens/notifications.dart';
import 'package:final_project/single_budget.dart';
import 'package:flutter/material.dart';

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
  // State for switches
  bool _isDarkMode = false;

  // Helper for building basic settings items
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    // 3. REFACTOR: Simplified trailing logic
    return ListTile(
      leading: Icon(icon, color: primaryText),
      title: Text(title, style: kTextTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: kTextTheme.bodySmall)
          : null,
      // Use the provided trailing widget or default to a chevron icon
      trailing: trailing ?? Icon(Icons.chevron_right, color: primaryText),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  // 4. REFACTOR: Created a separate widget for the Dark Mode toggle
  Widget _buildDarkModeToggle() {
    return _buildSettingsItem(
      icon: Icons.dark_mode,
      title: 'Dark Mode',
      trailing: Switch(
        value: _isDarkMode,
        onChanged: (bool value) {
          setState(() {
            _isDarkMode = value;
          });
        },
        activeColor: accentColor,
      ),
      onTap: () {}, // Do nothing on list tile tap
    );
  }

  // 🔔 UPDATED: Notifications is now a navigable item to Notifications()
  Widget _buildNotificationsItem(BuildContext context) {
    return _buildSettingsItem(
      icon: Icons.notifications_active,
      title: 'Notifications',
      onTap: () {
        // NAVIGATING TO Notifications()
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const Notifications()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Header Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage("assets/images/coin.jpg"),
                  ),
                  const SizedBox(height: 16),
                  Text('Shady_o.a', style: kTextTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: primaryText),
                      const SizedBox(width: 4),
                      Text('Kisii, Kenya', style: kTextTheme.bodySmall),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SingleBudget()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: primaryText,
                      shape: RoundedRectangleBorder(borderRadius: radiusSmall),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Savings Analysis',
                      style: kTextTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: primaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text('Settings', style: kTextTheme.headlineSmall),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // Dark Mode Toggle
                  _buildDarkModeToggle(),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🔔 Notifications (Now navigates to Notifications())
                  _buildNotificationsItem(context),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🔒 Change Password
                  _buildSettingsItem(
                    icon: Icons.lock_rounded,
                    title: 'Change Password',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // ℹ️ About
                  _buildSettingsItem(
                    icon: Icons.help_rounded,
                    title: 'About Penny Wise',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Penny Wise',
                        applicationVersion: '1.0.0',
                        children: [
                          Text(
                            'Penny Wise is a personal finance management app designed to help you track your expenses, manage budgets, and achieve your financial goals.',
                            style: kTextTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🚪 Logout
                  _buildSettingsItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Login(
                            showSignupPage: () {
                              // "Do nothing" placeholder function
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
