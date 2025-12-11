import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:flutter/material.dart';
  //
class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: CustomBackButton(),
        title: CustomHeader(headerName: "Notifications"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      // --- BODY: Empty State ---
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
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
                        color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text('No Notifications', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),

                      // Subtitle Text
                      Text(
                        'We\'ll let you know when there will be something to update you.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
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
