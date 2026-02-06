import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadUtils {
  /// Downloads a file from [url] to [fileName] and reports progress via [onProgress].
  /// Returns the full file path on success, or null on failure.
  static Future<String?> downloadFile(
      String url, {
        required String fileName,
        required Function(double) onProgress,
      }) async {
    try {
      // Request permissions on Android
      if (Platform.isAndroid) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            final manageStatus = await Permission.manageExternalStorage.request();
            if (!manageStatus.isGranted) return null;
          }
        }
      }

      print('Starting download: $url');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        print('Failed to download: ${streamedResponse.statusCode}');
        client.close();
        return null;
      }

      final total = streamedResponse.contentLength ?? 0;

      // Determine download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        print('No download directory available.');
        client.close();
        return null;
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Sanitize file name
      final safeFileName = fileName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
          .replaceAll(RegExp(r'\s+'), '_');

      final filePath = Platform.isAndroid
          ? '/storage/emulated/0/Download/$safeFileName'
          : '${directory.path}/$safeFileName';

      final file = File(filePath);
      final sink = file.openWrite();

      int downloaded = 0;
      final stopwatch = Stopwatch()..start();

      // Listen to the stream in chunks
      final subscription = streamedResponse.stream.listen(
            (chunk) async {
          sink.add(chunk);
          downloaded += chunk.length;

          // Update progress every 0.1 seconds
          if (stopwatch.elapsedMilliseconds >= 100 || downloaded == total) {
            final progress = total > 0 ? downloaded / total : 0.0;
            try {
              onProgress(progress);
            } catch (_) {}
            stopwatch.reset();
          }
        },
        onDone: () async {
          await sink.close();
          client.close();
          try {
            onProgress(1.0); // Ensure 100% progress
          } catch (_) {}
          print('Download complete: $filePath');
        },
        onError: (e) async {
          await sink.close();
          client.close();
          print('Download error: $e');
        },
        cancelOnError: true,
      );

      await subscription.asFuture(); // Wait until fully done
      return filePath;
    } catch (e) {
      print('Download failed: $e');
      return null;
    }
  }

  /// Check if a file is downloaded
  static Future<bool> isFileDownloaded(String fileName) async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) return false;
      final file = File('${dir.path}/$fileName');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// Delete a downloaded file
  static Future<void> deleteDownloadedFile(String fileName) async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) return;
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// List all downloaded APK files
  static Future<List<String>> listDownloadedFiles() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir == null) return [];
      final files = await dir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.apk'))
          .map((f) => f.path.split('/').last)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
