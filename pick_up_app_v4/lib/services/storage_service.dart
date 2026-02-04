import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pickup_delivery_app/models/po_model.dart';
import 'package:pickup_delivery_app/models/company_model.dart';
import 'package:pickup_delivery_app/models/delivery_model.dart';
import 'package:pickup_delivery_app/models/route_order_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<String> get _appDataPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> getDataFilePath(String filename) async {
    final path = await _appDataPath;
    return '$path/$filename.json';
  }

  // PO Data
  Future<List<PickupOrder>> loadPOData() async {
    try {
      final file = File(await getDataFilePath('po_data'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as List;
        return data.map((item) => PickupOrder.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading PO data: $e');
    }
    return [];
  }

  Future<void> savePOData(List<PickupOrder> pos) async {
    try {
      final file = File(await getDataFilePath('po_data'));
      final data = pos.map((po) => po.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving PO data: $e');
    }
  }

  // Company Database
  Future<Map<String, RouteCompanies>> loadCompanyDatabase() async {
    try {
      final file = File(await getDataFilePath("company_database"));

      if (!await file.exists()) {
        return {};
      }

      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        print("Company database file is empty, starting fresh");
        return {};
      }

      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        print("Company database file is not a map, resetting");
        return {};
      }

      final companies = <String, RouteCompanies>{};

      decoded.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          companies[key] = RouteCompanies.fromJson(
            key,
            value,
          );
        }
      });

      return companies;
    } catch (e) {
      print("Error loading company database: $e");
      return {};
    }
  }


  Future<void> saveCompanyDatabase(Map<String, RouteCompanies> database) async {
    try {
      final file = File(await getDataFilePath('company_database'));
      final data = <String, dynamic>{};

      database.forEach((key, value) {
        data[key] = value.toJson();
      });

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving company database: $e');
    }
  }

  // Delivery Data
  Future<DeliveryData?> loadDeliveryData() async {
    try {
      final file = File(await getDataFilePath('delivery_data'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        return DeliveryData.fromJson(data);
      }
    } catch (e) {
      print('Error loading delivery data: $e');
    }
    return null;
  }

  Future<void> saveDeliveryData(DeliveryData data) async {
    try {
      final file = File(await getDataFilePath('delivery_data'));
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (e) {
      print('Error saving delivery data: $e');
    }
  }

  // Route Order Cache
  Future<Map<String, List<RouteStop>>> loadRouteOrderCache() async {
    try {
      final file = File(await getDataFilePath('route_order_cache'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final cache = <String, List<RouteStop>>{};

        data.forEach((key, value) {
          if (value is List) {
            cache[key] = value.map((item) => RouteStop.fromJson(item)).toList();
          }
        });

        return cache;
      }
    } catch (e) {
      print('Error loading route order cache: $e');
    }
    return {};
  }

  Future<void> saveRouteOrderCache(Map<String, List<RouteStop>> cache) async {
    try {
      final file = File(await getDataFilePath('route_order_cache'));
      final data = <String, dynamic>{};

      cache.forEach((key, value) {
        data[key] = value.map((stop) => stop.toJson()).toList();
      });

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving route order cache: $e');
    }
  }

  // Route Order Data (full dataset separate from cache)
  Future<Map<String, List<RouteStop>>> loadRouteOrderData() async {
    try {
      final file = File(await getDataFilePath('route_order_data'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final orders = <String, List<RouteStop>>{};

        data.forEach((key, value) {
          if (value is List) {
            orders[key] = value.map((item) => RouteStop.fromJson(item)).toList();
          }
        });

        return orders;
      }
    } catch (e) {
      print('Error loading route order data: $e');
    }
    return {};
  }

  Future<void> saveRouteOrderData(Map<String, List<RouteStop>> dataMap) async {
    try {
      final file = File(await getDataFilePath('route_order_data'));
      final data = <String, dynamic>{};

      dataMap.forEach((key, value) {
        data[key] = value.map((stop) => stop.toJson()).toList();
      });

      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error saving route order data: $e');
    }
  }

  // Settings via SharedPreferences
  static Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  // App Settings file (JSON) - includes driverId, selectedRoute, selectedCompany, urls, theme
  Future<Map<String, dynamic>> loadAppSettingsFile() async {
    try {
      final file = File(await getDataFilePath('app_settings'));
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        return data;
      }
    } catch (e) {
      print('Error loading app settings file: $e');
    }
    return {};
  }

  Future<void> saveAppSettingsFile(Map<String, dynamic> settings) async {
    try {
      final file = File(await getDataFilePath('app_settings'));
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      print('Error saving app settings file: $e');
    }
  }
  Future<void> save_all({
    List<PickupOrder>? po_data,
    Map<String, RouteCompanies>? company_database,
    DeliveryData? delivery_data,
    Map<String, List<RouteStop>>? route_order_data,
    Map<String, List<RouteStop>>? route_order_cache,
    Map<String, dynamic>? app_settings,
  }) async {
    if (po_data != null) {
      await savePOData(po_data);
    }
    if (company_database != null) {
      await saveCompanyDatabase(company_database);
    }
    if (delivery_data != null) {
      await saveDeliveryData(delivery_data);
    }
    if (route_order_data != null) {
      await saveRouteOrderData(route_order_data);
    }
    if (route_order_cache != null) {
      await saveRouteOrderCache(route_order_cache);
    }
    if (app_settings != null) {
      await saveAppSettingsFile(app_settings);
    }
  }

}