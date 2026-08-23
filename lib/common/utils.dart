import 'package:flutter/material.dart';

void dismissKeyboard(BuildContext context) {
  final focusScope = FocusScope.of(context);
  if (!focusScope.hasPrimaryFocus) focusScope.unfocus();
}

Widget dismissKeyboardWrapper(BuildContext context, Widget child) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => dismissKeyboard(context),
    child: child,
  );
}
