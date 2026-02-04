import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadUtils {
  static Future<String?> downloadFile(
      String url, {
        required String fileName,
        required Function(double) onProgress,
      }) async {
    try {
      // Check and request permissions BEFORE downloading
      if (Platform.isAndroid) {
        // First, check if we have storage permission
        var storageStatus = await Permission.storage.status;

        if (!storageStatus.isGranted) {
          // Request storage permission
          storageStatus = await Permission.storage.request();

          if (!storageStatus.isGranted) {
            // If still not granted, try requesting manage external storage (for Android 11+)
            if (await Permission.manageExternalStorage.isRestricted) {
              // Open app settings to let user grant permission manually
              await openAppSettings();
              return null;
            }

            // Try requesting manage external storage
            final manageStatus = await Permission.manageExternalStorage.request();
            if (!manageStatus.isGranted) {
              print('Storage permission denied by user');
              return null;
            }
          }
        }

        // Also request install packages permission for Android 8+
        if (!await Permission.requestInstallPackages.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      print('Starting download from: $url');

      // Create HTTP client
      final client = http.Client();
      final request = await client.get(Uri.parse(url));

      if (request.statusCode != 200) {
        print('Failed to download: ${request.statusCode}');
        client.close();
        return null;
      }

      // Get downloads directory
      Directory? directory;

      if (Platform.isAndroid) {
        // Try multiple approaches to get downloads directory
        try {
          // First try getExternalStorageDirectory (deprecated but still works)
          directory = await getExternalStorageDirectory();
          print('Got external storage directory: ${directory?.path}');

          if (directory == null) {
            // Fallback to getApplicationDocumentsDirectory
            directory = await getApplicationDocumentsDirectory();
            print('Fell back to documents directory: ${directory.path}');
          }
        } catch (e) {
          print('Error getting directories: $e');
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        print('Could not get any directory');
        client.close();
        return null;
      }

      // Create the directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created directory: ${directory.path}');
      }

      // Sanitize filename
      final safeFileName = fileName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')  // Remove invalid characters
          .replaceAll(RegExp(r'\s+'), '_');  // Replace multiple spaces

      print('Safe file name: $safeFileName');

      // Create file path - try different approaches
      String filePath;

      if (Platform.isAndroid) {
        // Try to save directly to Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          filePath = '${downloadsDir.path}/$safeFileName';
          print('Using direct downloads path: $filePath');
        } else {
          // Fallback to app's directory
          filePath = '${directory.path}/$safeFileName';
          print('Using app directory path: $filePath');
        }
      } else {
        filePath = '${directory.path}/$safeFileName';
      }

      final file = File(filePath);

      // Write the file with progress tracking
      print('Writing file to: $filePath');

      // Get the bytes
      final bytes = request.bodyBytes;
      final total = bytes.length;

      // Write in chunks to track progress
      const chunkSize = 1024 * 1024; // 1MB chunks
      final sink = file.openWrite();
      int written = 0;

      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize) < bytes.length ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        sink.add(chunk); // Removed await - this returns void
        await sink.flush(); // Flush to ensure chunk is written

        written += chunk.length;

        // Update progress
        final double progress = total > 0 ? written / total : 0.0; // Cast to double
        onProgress(progress);
        print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
      }

      await sink.close();
      client.close();

      print('File downloaded successfully!');
      print('File path: $filePath');
      print('File size: ${await file.length()} bytes');

      // Verify file exists
      if (await file.exists()) {
        print('File verified to exist');
        return filePath;
      } else {
        print('File does not exist after writing!');
        return null;
      }
    } catch (e) {
      print('Error downloading file: $e');
      print('Stack trace: ${e.toString()}');
      return null;
    }
  }

  static Future<bool> isFileDownloaded(String fileName) async {
    try {
      // Try multiple locations
      final List<String> possiblePaths = [];

      if (Platform.isAndroid) {
        // Direct Downloads folder
        possiblePaths.add('/storage/emulated/0/Download/$fileName');

        // Sanitized version
        final safeFileName = fileName.replaceAll(' ', '_');
        possiblePaths.add('/storage/emulated/0/Download/$safeFileName');

        // App directories
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          possiblePaths.add('${extDir.path}/$fileName');
          possiblePaths.add('${extDir.path}/$safeFileName');
        }

        final appDir = await getApplicationDocumentsDirectory();
        possiblePaths.add('${appDir.path}/$fileName');
        possiblePaths.add('${appDir.path}/$safeFileName');
      }

      for (final path in possiblePaths) {
        final file = File(path);
        if (await file.exists()) {
          print('Found file at: $path');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking file: $e');
      return false;
    }
  }

  static Future<void> deleteDownloadedFile(String fileName) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return;

      final safeFileName = fileName.replaceAll(' ', '_');
      final filePath = '${directory.path}/$safeFileName';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('File deleted: $filePath');
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  static Future<List<String>> listDownloadedFiles() async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return [];

      final dir = Directory(directory.path);
      final files = await dir.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.apk'))
          .map((file) => file.path.split('/').last)
          .toList();
    } catch (e) {
      return [];
    }
  }
}