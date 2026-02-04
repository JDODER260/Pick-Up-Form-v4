import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<Permission> permissions;

  const PermissionRequestDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.permissions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Request'),
        ),
      ],
    );
  }
}