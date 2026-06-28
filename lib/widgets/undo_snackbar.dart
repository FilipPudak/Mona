import 'package:flutter/material.dart';

void showUndoSnackBar({
  required ScaffoldMessengerState messenger,
  required String message,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          onUndo();
          messenger.hideCurrentSnackBar();
        },
      ),
    ),
  );
  Future.delayed(duration, () {
    messenger.hideCurrentSnackBar();
  });
}
