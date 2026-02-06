import 'package:flutter/material.dart';
import 'package:pickup_delivery_app/services/update_service.dart';
import 'package:pickup_delivery_app/utils/download_utils.dart';
import 'package:pickup_delivery_app/widgets/progress_dialog.dart';
import 'dart:async';


class UpdateManager {
  final UpdateService _updateService = UpdateService();

  Future<void> checkAndUpdate(
    BuildContext context, {
    required String updateCheckUrl,
    required String currentVersion,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Checking for updates...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    try {
      final downloadUrl =
          await _updateService.checkForUpdate(updateCheckUrl, currentVersion);

      Navigator.pop(context); // Close loading dialog

      if (downloadUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App is up to date!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      final fileName = downloadUrl.split('/').last;

      // Ask user to confirm download
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Update Available'),
          content:
              Text('A new version is available. Do you want to download it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadAndInstall(context, downloadUrl, fileName);
              },
              child: Text('Download'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking for updates'),
          backgroundColor: Colors.red,
        ),
      );
      print('Update check error: $e');
    }
  }

  Future<void> _downloadAndInstall(
    BuildContext context,
    String downloadUrl,
    String fileName,
  ) async {
    print("Starting download from: $downloadUrl");
    print("File name: $fileName");

    // Show progress dialog
    bool downloadComplete = false;
    String? downloadedFilePath;

    // Create a completer for the download and a progress stream
    final completer = Completer<String?>();
    final progressController = StreamController<double>();

    // Start download in background; forward progress into the controller
    DownloadUtils.downloadFile(
      downloadUrl,
      fileName: fileName,
      onProgress: (progress) {
        try {
          if (!progressController.isClosed) progressController.add(progress);
        } catch (_) {}
      },
    ).then((filePath) {
      downloadedFilePath = filePath;
      downloadComplete = true;
      if (!completer.isCompleted) completer.complete(filePath);
    }).catchError((e) {
      if (!completer.isCompleted) completer.completeError(e);
    }).whenComplete(() {
      // close the progress stream when done
      try {
        if (!progressController.isClosed) progressController.close();
      } catch (_) {}
    });

    // Show the progress dialog (pass the stream)
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        downloadFuture: completer.future,
        fileName: fileName,
        progressStream: progressController.stream,
      ),
    );

    if (success == true && downloadedFilePath != null) {
      // Show installation dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Install Update'),
          content: Text('Ready to install the update. Do you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _updateService.installUpdate(downloadedFilePath!);
                  print("Installation initiated");
                } catch (e) {
                  print("Installation failed: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to install: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Install Now'),
            ),
          ],
        ),
      );
    } else if (!downloadComplete) {
      print("Download failed or was cancelled!");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
