import "dart:io";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import "package:version/version.dart";

class UpdateService {
  static const MethodChannel _channel = MethodChannel("apk_installer");

  Future<String?> checkForUpdate(
      String update_check_url,
      String current_version,
      ) async {
    print("Checking for update from: $update_check_url");
    print("Current version: $current_version");

    try {
      final response = await http.get(Uri.parse(update_check_url));

      if (response.statusCode != 200) {
        print("HTTP Error: ${response.statusCode}");
        return null;
      }

      final html = response.body;
      final apk_pattern = RegExp(r'href="([^"]+\.apk)"', caseSensitive: false);
      final version_pattern = RegExp(r'-(\d+(?:\.\d+)+)-');

      final current_parsed_version = Version.parse(current_version);
      Version? latest_version;
      String? latest_apk_filename;

      print("Found ${apk_pattern.allMatches(html).length} APK files");

      for (final match in apk_pattern.allMatches(html)) {
        final filename = match.group(1)!;
        print("Found APK: $filename");

        final version_match = version_pattern.firstMatch(filename);
        if (version_match == null) {
          print("No version found in: $filename");
          continue;
        }

        final version_string = version_match.group(1)!;
        print("Version string: $version_string");

        Version parsed_version;
        try {
          parsed_version = Version.parse(version_string);
        } catch (_) {
          print("Failed to parse version: $version_string");
          continue;
        }

        print("Parsed version: $parsed_version");
        print("Current version: $current_parsed_version");

        if (parsed_version > current_parsed_version) {
          print("Newer version found: $parsed_version > $current_parsed_version");
          if (latest_version == null || parsed_version > latest_version) {
            latest_version = parsed_version;
            latest_apk_filename = filename;
            print("Setting as latest: $filename");
          }
        }
      }

      if (latest_apk_filename == null) {
        print("No newer version found");
        return null;
      }

      final clean_base_url = update_check_url.replaceAll(RegExp(r'/+$'), "");
      final downloadUrl = "$clean_base_url/$latest_apk_filename";
      print("Download URL: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print("Update check error: $e");
      return null;
    }
  }

  Future<void> installUpdate(String file_path) async {
    try {
      print("Attempting to install from: $file_path");

      // Check if file exists
      final file = File(file_path);
      if (!await file.exists()) {
        print("File does not exist: $file_path");
        throw Exception("APK file not found");
      }

      print("File exists, size: ${await file.length()} bytes");

      // Request install permission for Android 8.0+
      if (Platform.isAndroid) {
        print("Checking install permission...");
        if (!await Permission.requestInstallPackages.isGranted) {
          print("Requesting install permission...");
          final status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            print("Install permission denied");
            throw Exception("Install permission denied by user");
          }
        }
        print("Install permission granted");
      }

      // Call the platform method
      print("Invoking install_apk method...");
      await _channel.invokeMethod(
        "install_apk",
        {
          "file_path": file_path,
        },
      );

      print("Install method invoked successfully");
    } catch (e) {
      print("Install error: $e");
      rethrow;
    }
  }
}