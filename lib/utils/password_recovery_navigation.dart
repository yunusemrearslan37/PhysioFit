import 'package:flutter/material.dart';

import '../screens/auth/reset_password_screen.dart';
import 'app_navigator.dart';
import 'password_recovery_state.dart';

void openPasswordRecoveryScreen({bool replaceEntireStack = false}) {
  if (!isPasswordRecoveryPending || isRecoveryNavigationHandled) return;

  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  isRecoveryNavigationHandled = true;

  final route = MaterialPageRoute<void>(
    builder: (context) => const ResetPasswordScreen(),
  );

  if (replaceEntireStack) {
    navigator.pushAndRemoveUntil(route, (route) => false);
    return;
  }

  navigator.push(route).whenComplete(() {
    if (isPasswordRecoveryPending) {
      isRecoveryNavigationHandled = false;
    }
  });
}
