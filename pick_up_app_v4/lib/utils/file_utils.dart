import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  static Future<String> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the public Downloads directory
      Directory? directory;
      try {
        if (await Directory('/storage/emulated/0/Download').exists()) {
          directory = Directory('/storage/emulated/0/Download');
        } else {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getExternalStorageDirectory();
      }
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    } else {
      // For other platforms
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  static Future<String> getPDFDirectory(String route, DateTime date) async {
    final downloadDir = await getDownloadDirectory();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final pdfPath = path.join(downloadDir, 'PickUpForms', route, dateStr);
    final dir = Directory(pdfPath);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return pdfPath;
  }

  static Future<String> generatePDFPath(String route, String company, DateTime date) async {
    final pdfDir = await getPDFDirectory(route, date);
    final timestamp = '${date.hour}${date.minute}${date.second}';
    final safeCompany = company.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

    return path.join(pdfDir, 'receipt_${safeCompany}_$timestamp.pdf');
  }

  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}