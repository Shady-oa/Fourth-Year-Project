import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/single_budget.dart';
import 'package:flutter/material.dart';

// 1. FIXED: Removed the required 'onToggleTheme' callback from the constructor.
// It is now an independent page/widget.
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
  // State for switches (Notifications and Theme)
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;

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
        // The onChanged function now performs the state update and "do-nothing" action
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

  // 4. REFACTOR: Created a separate widget for the Notifications toggle
  Widget _buildNotificationsToggle() {
    return _buildSettingsItem(
      icon: Icons.notifications_active,
      title: 'Notifications',
      trailing: Switch(
        value: _isNotificationsEnabled,
        onChanged: (bool value) {
          setState(() {
            _isNotificationsEnabled = value;
          });
        },
        activeColor: accentColor,
      ),
      onTap: () {}, // Do nothing on list tile tap
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
                    backgroundImage: const AssetImage(
                      "assets/images/profile.png",
                    ),
                    backgroundColor: Colors.grey[200],
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
                      backgroundColor: primaryBg,
                      // The foreground color should contrast with primaryBg
                      foregroundColor: primaryBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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

            const SizedBox(height: 24),

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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text('Settings', style: kTextTheme.headlineSmall),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // Dark Mode Toggle
                  _buildDarkModeToggle(),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🔔 Notifications Toggle
                  _buildNotificationsToggle(),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🔐 Privacy (Extracted from Account ExpansionTile)

                  // 🔒 Security (Extracted from Account ExpansionTile)
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: 'Security',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Security Settings')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // ℹ️ About
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "penny wise",
                        applicationVersion: "1.0.0",
                        applicationLegalese: "© 2025 Magari Konnect",
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),

                  // 🚪 Logout (Extracted from Account ExpansionTile)
                  _buildSettingsItem(
                    icon: Icons.logout,
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
