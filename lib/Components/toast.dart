import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

void showCustomToast({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
  required IconData icon,
  // error use Icons.error_outline_rounded
  // warning use Icons.warning_amber_rounded
  // success use Icons.check_circle_outline_rounded
}) {
  ToastService.showToast(
    context,
    message: message,
    backgroundColor: backgroundColor,
    dismissDirection: DismissDirection.horizontal,
    expandedHeight: 80,
    isClosable: false,
    leading: Icon(icon, color: textLightMode),
    length: ToastLength.long,
    positionCurve: Curves.bounceInOut,
    slideCurve: Curves.easeInOut,
    shadowColor: backgroundColor,
    messageStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: textLightMode,
    ),
  );
}
