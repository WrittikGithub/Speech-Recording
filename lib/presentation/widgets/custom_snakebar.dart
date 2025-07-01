import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required ContentType contentType,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    if (scaffoldMessengerKey?.currentState != null) {
      scaffoldMessengerKey!.currentState!
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } else {
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      } else {
        print('CustomSnackBar: No ScaffoldMessenger found with key or context.');
      }
    }
  }
}

// Usage example:
// CustomSnackBar.show(
//   context: context,
//   title: 'Success!',
//   message: 'Your action was completed successfully.',
//   contentType: ContentType.success,
//   scaffoldMessengerKey: yourGlobalKey,
// );