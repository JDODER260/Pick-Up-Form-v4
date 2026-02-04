import "dart:io";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";

class PermissionUtils {
  static Future<bool> request_all_permissions(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    // REQUEST_INSTALL_PACKAGES cannot be requested at runtime
    final install_granted =
    await Permission.requestInstallPackages.isGranted;

    if (!install_granted) {
      await _show_install_permission_dialog(context);
      return false;
    }

    return true;
  }

  static Future<void> _show_install_permission_dialog(
      BuildContext context,
      ) async {
    if (!context.mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialog_context) {
        return AlertDialog(
          title: Text("Permission Required"),
          content: Text(
            "To install app updates, this app must be allowed "
                "to install packages from unknown sources.\n\n"
                "Please enable this permission in system settings.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialog_context).pop();
                await openAppSettings();
              },
              child: Text("Open Settings"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialog_context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
  static Future<void> open_app_settings() async {
    await openAppSettings();
  }

}
