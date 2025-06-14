import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showMessage(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 2),
    bool loading = false,
  }) {
    messengerKey.currentState?.removeCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(message,
                      style: const TextStyle(
                          color: Default_Theme.primaryColor1, fontSize: 16)),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Default_Theme.primaryColor1),
                      ),
                    ),
                  ),
                ],
              )
            : Text(message,
                style: const TextStyle(
                    color: Default_Theme.primaryColor1, fontSize: 16)),
        duration: loading ? const Duration(minutes: 1) : duration,
        showCloseIcon: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        closeIconColor: Default_Theme.primaryColor1,
        elevation: 0,
        action: action,
        backgroundColor: const Color.fromARGB(255, 16, 15, 15),
      ),
    );
  }
}
