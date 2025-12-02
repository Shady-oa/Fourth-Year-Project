import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandGreen,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back_ios, color: primaryBg),
                      ),
                      Spacer(),
                      Text('Profile', style: kTextTheme.displaySmall),
                      Spacer(),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryBg,
                        child: Icon(
                          Icons.notifications_outlined,
                          color: primaryText,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 80),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryBg,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          SizedBox(height: 80),
                          Text('Username', style: kTextTheme.bodyLarge),
                          SizedBox(height: 40),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: accentColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: primaryBg,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Edit Profile',
                                style: kTextTheme.bodyMedium,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: accentColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.shield_outlined,
                                    color: primaryBg,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Security', style: kTextTheme.bodyMedium),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: accentColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.settings_outlined,
                                    color: primaryBg,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Settings', style: kTextTheme.bodyMedium),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: accentColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.support_agent_outlined,
                                    color: primaryBg,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Help', style: kTextTheme.bodyMedium),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: accentColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.logout_outlined,
                                    color: primaryBg,
                                    size: 40,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Logout', style: kTextTheme.bodyMedium),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 80 + 20 + 10 + 40 - 60,
              left: MediaQuery.of(context).size.width * 0.5 - 60,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/image/coin.jpg',),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
