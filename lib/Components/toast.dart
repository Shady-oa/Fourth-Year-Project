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
    messageStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.surface),
    slideCurve: Curves.easeInOut,
    shadowColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
  );
}

