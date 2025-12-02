import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: spacerMedium,
                left: spacerMedium,
                bottom: 50.0, // Custom value
                right: spacerMedium,
              ),
              child: Row(
                children: [
                  Text("AI Assistant", style: kTextTheme.headlineSmall),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryText,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: primaryBg,
                    ),
                  ),
                ],
              ),
            ),

            //main content
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50), // Custom value
                      topRight: Radius.circular(50), // Custom value
                    ),
                    color: primaryText,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 45, // Custom value
                      left: 50, // Custom value
                      right: 50, // Custom value
                      bottom: spacerSmall,
                    ),
                    child: Column(
                      children: [
                        // Add your AI assistant content here
                      ],
                    ),
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
