import 'package:final_project/AuthScreens/change_pwd.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Components/Custom_header.dart';
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
  // State for switches
  bool _isDarkMode = false;

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface,
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  
  Widget _buildDarkModeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final isDarkMode = themeProvider.currentTheme == darkMode;

    return _buildSettingsItem(
      icon: Icons.dark_mode,
      title: 'Dark Mode',
      trailing: Switch(
        value: isDarkMode,
        onChanged: (bool value) {
          themeProvider.toggleTheme();
        },
        activeThumbColor: accentColor,
      ),
      onTap: () {
        themeProvider.toggleTheme();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: CustomHeader(headerName: "Profile"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: paddingAllMedium,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage(
                      "assets/image/icon 2.png",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shady_o.a',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kisii, Kenya',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),

                  _buildDarkModeToggle(),

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
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),

                  // 🚪 Logout
                  _buildSettingsItem(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Login(showSignupPage: () {}),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
