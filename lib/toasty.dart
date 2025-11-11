import 'package:flutter/material.dart';
import 'package:toasty_box/toast_enums.dart';
import 'package:toasty_box/toast_service.dart';

void showCustomToast(BuildContext context, String message) {
  ToastService.showToast(
    context,
    message: message,
    backgroundColor: Color.fromARGB(154, 229, 56, 53),
    dismissDirection: DismissDirection.endToStart,
    expandedHeight: 80,
    isClosable: true,
    leading: Icon(Icons.error_outline),
    length: ToastLength.medium,
    positionCurve: Curves.bounceInOut,
    messageStyle: TextStyle(
      fontSize: 18,
      color: Colors.white,
    ),
    slideCurve: Curves.easeInOut,
    shadowColor: Color.fromARGB(199, 153, 151, 151),
  );
}
void how(String msg, BuildContext context) {
  showCustomToast(context, msg);
}

