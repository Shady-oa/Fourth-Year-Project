import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/home/settings_card.dart';
import 'package:final_project/SecondaryScreens/AuthScreens/login.dart';
import 'package:final_project/SecondaryScreens/Settings/about_page.dart';
import 'package:final_project/SecondaryScreens/Settings/developers_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shows the user profile & settings bottom sheet.
void showProfileSheet(
  BuildContext context, {
  required String? username,
  required String? profileImage,
  required VoidCallback onPickImage,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: paddingAllMedium,
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Profile banner
              Container(
                padding: paddingAllLarge,
                decoration: BoxDecoration(
                  borderRadius: radiusLarge,
                  gradient: LinearGradient(
                    colors: [brandGreen, brandGreen.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                          backgroundImage:
                              (profileImage == null || profileImage.isEmpty)
                              ? const AssetImage('assets/image/icon.png')
                                    as ImageProvider
                              : NetworkImage(profileImage),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              onPickImage();
                            },
                            child: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Icon(
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
                            username ?? 'Penny User',
                            style: Theme.of(ctx).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Kisii, Kenya',
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
                  'Settings',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Settings Container
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    ctx,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: radiusLarge,
                  border: Border.all(
                    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    // Dark mode toggle
                    SettingsCard(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      trailing: Switch(
                        value:
                            Provider.of<ThemeProvider>(
                              ctx,
                              listen: true,
                            ).currentTheme.brightness ==
                            Brightness.dark,
                        onChanged: (_) => Provider.of<ThemeProvider>(
                          ctx,
                          listen: false,
                        ).toggleTheme(),
                        activeTrackColor: brandGreen.withOpacity(0.4),
                        activeThumbColor: brandGreen,
                      ),
                      onTap: () => Provider.of<ThemeProvider>(
                        ctx,
                        listen: false,
                      ).toggleTheme(),
                    ),
                    SettingsCard(
                      icon: Icons.info_outline,
                      title: 'About Penny Wise',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      },
                    ),
                    SettingsCard(
                      icon: Icons.code,
                      title: 'Developers',
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DevelopersPage(),
                          ),
                        );
                      },
                    ),
                    SettingsCard(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: () {
                        Navigator.pop(ctx);
                        AppToast.success(context, 'Logged out successfully!');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Login(showSignupPage: () {}),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}
