import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      // --- BODY: Empty State ---
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.arrow_back_ios, color: primaryText),
                ),
                Text('Notifications', style: kTextTheme.headlineSmall),
              ],
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Notification Icon
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 64,
                        color: primaryText.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text('No Notifications', style: kTextTheme.headlineSmall),
                      const SizedBox(height: 8),

                      // Subtitle Text
                      Text(
                        'We\'ll let you know when there will be something to update you.',
                        textAlign: TextAlign.center,
                        style: kTextTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
