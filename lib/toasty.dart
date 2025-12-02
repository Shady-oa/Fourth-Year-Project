import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

void showCustomToast({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  ToastService.showToast(
    context,
    message: message,
    backgroundColor: backgroundColor,
    dismissDirection: DismissDirection.endToStart,
    expandedHeight: 80,
    isClosable: true,
    leading: Icon(icon),
    length: ToastLength.medium,
    positionCurve: Curves.bounceInOut,
    messageStyle: kTextTheme.bodyLarge!.copyWith(color: primaryBg),
    slideCurve: Curves.easeInOut,
    shadowColor: primaryText.withOpacity(0.5),
  );
}

