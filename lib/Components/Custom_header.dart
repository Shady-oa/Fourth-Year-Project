import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Primary_Screens/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomHeader extends StatelessWidget {
  final String headerName;

  const CustomHeader({Key? key, required this.headerName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/penny.svg',
                  height: 35,
                  width: 35,
                  colorFilter: const ColorFilter.mode(
                    brandGreen,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: spacerTiny),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Penny",
                      style: kTextTheme.bodyLarge?.copyWith(color: brandGreen),
                    ),
                    Text(
                      'Wise',
                      style: kTextTheme.bodyLarge?.copyWith(color: brandGreen),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(headerName, style: kTextTheme.headlineSmall),
            const Spacer(),
            if (headerName != 'Notifications')
              IconButton(
                icon: const Icon(
                  Icons.circle_notifications_rounded,
                  size: 30,
                  color: primaryText,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Notifications(),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: spacerMedium),
      ],
    );
  }
}
