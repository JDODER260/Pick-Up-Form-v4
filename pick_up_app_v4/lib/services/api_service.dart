import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // << add this import
import 'package:pickup_delivery_app/models/delivery_model.dart';
import 'package:pickup_delivery_app/models/route_order_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> uploadPOs(
      List<Map<String, dynamic>> pos, String uploadUrl) async {
    try {
      // Only for dev / self-signed certs
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final client = IOClient(httpClient);

      final response = await client.post(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pos),
      );

      client.close();

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) return {};
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCompanyDatabase(String companyDbUrl) async {
    try {
      final response = await http.get(Uri.parse(companyDbUrl));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch company DB: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fetch failed: $e');
    }
  }

  Future<DeliveryData> fetchDeliveryData(String deliveryUrl, String route) async {
    try {
      final url = Uri.parse('$deliveryUrl?route=$route');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DeliveryData.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to fetch delivery data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fetch failed: $e');
    }
  }

  Future<List<RouteStop>> fetchRouteOrder(String routeOrderUrl, String route) async {
    try {
      final url = Uri.parse('${routeOrderUrl.replaceAll(RegExp(r'/+$'), '')}/$route');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stops = <RouteStop>[];

        // Handle different response formats
        if (data is List) {
          for (var item in data) {
            stops.add(RouteStop.fromJson(item));
          }
        } else if (data is Map) {
          if (data['data'] is List) {
            for (var item in data['data']) {
              stops.add(RouteStop.fromJson(item));
            }
          } else if (data['stops'] is List) {
            for (var item in data['stops']) {
              stops.add(RouteStop.fromJson(item));
            }
          }
        }

        return stops;
      } else {
        throw Exception('Failed to fetch route order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fetch failed: $e');
    }
  }

  Future<String> checkForUpdates(String updateCheckUrl, String currentVersion) async {
    try {
      final response = await http.get(Uri.parse(updateCheckUrl));

      if (response.statusCode == 200) {
        // Parse HTML to find APK files
        final html = response.body;
        // You'll need to implement parsing logic similar to Python regex
        return ''; // Return latest version or empty string
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}