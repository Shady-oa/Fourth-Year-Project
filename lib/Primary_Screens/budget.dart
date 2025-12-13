import 'package:final_project/Components/Custom_header.dart';
import 'package:flutter/material.dart';

class Budget extends StatelessWidget {
  const Budget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: CustomHeader(headerName: "Budgets"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // budget Icon
                      Icon(
                        Icons.receipt_rounded,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'No Budgets',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle Text
                      Text(
                        'This feature is currently under development.',
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
