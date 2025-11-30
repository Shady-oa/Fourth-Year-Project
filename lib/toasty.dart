import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

void showCustomToast(BuildContext context, String message) {
  ToastService.showToast(
    context,
    message: message,
    backgroundColor: Colors.red,
    dismissDirection: DismissDirection.endToStart,
    expandedHeight: 80,
    isClosable: true,
    leading: const Icon(Icons.error_outline),
    length: ToastLength.medium,
    positionCurve: Curves.bounceInOut,
    messageStyle: kTextTheme.bodyLarge!.copyWith(color: primaryBg),
    slideCurve: Curves.easeInOut,
    shadowColor: primaryText.withOpacity(0.5),
  );
}

void how(String msg, BuildContext context) {
  showCustomToast(context, msg);
}

