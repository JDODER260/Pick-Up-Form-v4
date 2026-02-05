import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pickup_delivery_app/models/company_model.dart';
import 'package:pickup_delivery_app/models/delivery_model.dart';
import 'package:pickup_delivery_app/models/route_order_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';
import 'package:pickup_delivery_app/services/api_service.dart';

class AppProvider with ChangeNotifier {
  // App state
  bool _isInitializing = false;


  String _appMode = 'delivery'; // 'delivery' or 'pickup'
  String _selectedRoute = '';
  String _selectedCompany = '';
  String _driverId = '';
  String _currentVersion = '4.0.1';

  // Theme
  ThemeMode _themeMode = ThemeMode.system;

  // URLs
  String _uploadUrl = "https://doublersharpening.com/api/upload_po/";
  String _updateCheckUrl = "https://doublersharpening.com/media/mypoapp/";
  String _companyDbUrl = "https://doublersharpening.com/api/company_db/";
  String _deliveryUrl = "https://doublersharpening.com/api/delivery_pos/";
  String _routeOrderUrl = "https://doublersharpening.com/api/route_order/";

  // Data
  Map<String, RouteCompanies> _companyDatabase = {};
  List<String> _availableRoutes = [];
  List<String> _companyNames = [];

  // Delivery data
  DeliveryData? _deliveryData;
  int _currentDeliveryIndex = 0;

  // Route order data
  List<RouteStop> _routeOrderStops = [];
  String _routeOrderViewMode = 'overview';
  int _routeOrderCurrentIndex = 0;
  bool _shouldSaveSettings = true;


  // Getters
  String get appMode => _appMode;
  String get selectedRoute => _selectedRoute;
  String get selectedCompany => _selectedCompany;
  String get driverId => _driverId;
  String get currentVersion => _currentVersion;
  ThemeMode get themeMode => _themeMode;
  String get uploadUrl => _uploadUrl;
  String get updateCheckUrl => _updateCheckUrl;
  String get companyDbUrl => _companyDbUrl;
  String get deliveryUrl => _deliveryUrl;
  String get routeOrderUrl => _routeOrderUrl;
  Map<String, RouteCompanies> get companyDatabase => _companyDatabase;
  List<String> get availableRoutes => _availableRoutes;
  List<String> get companyNames => _companyNames;
  DeliveryData? get deliveryData => _deliveryData;
  int get currentDeliveryIndex => _currentDeliveryIndex;
  List<RouteStop> get routeOrderStops => _routeOrderStops;
  String get routeOrderViewMode => _routeOrderViewMode;
  int get routeOrderCurrentIndex => _routeOrderCurrentIndex;
  bool get isInitializing => _isInitializing;



  // Setters
  set appMode(String mode) {
    _appMode = mode;
    saveSettings();
    notifyListeners();
  }

  set selectedRoute(String route) {
    _selectedRoute = route;
    saveSettings();
    updateCompanyNames();
    notifyListeners();
  }

  set selectedCompany(String company) {
    _selectedCompany = company;
    saveSettings();
    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    saveSettings();
    notifyListeners();
  }

  // Methods
  Future<void> initializeApp() async {
    if (_isInitializing) return; // Prevent re-entrance
    _isInitializing = true;

    try {
      // Temporarily disable settings save during initialization
      _shouldSaveSettings = false;

      await loadSettings();
      await loadCompanyDatabase();
      await loadDeliveryData();
      await loadRouteOrderCache();

      // Re-enable settings save after initialization
      _shouldSaveSettings = true;

      // Auto sync on startup
      await syncCompanyDatabaseOnStartup();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> loadSettings() async {
    // Load legacy prefs first
    final prefs = await SharedPreferences.getInstance();
    _appMode = prefs.getString("appMode") ?? "delivery";
    _selectedRoute = prefs.getString("selectedRoute") ?? "";
    _selectedCompany = prefs.getString("selectedCompany") ?? "";
    _driverId = prefs.getString("driverId") ?? "";
    _themeMode = ThemeMode.values[prefs.getInt("themeMode") ?? 0];

    _uploadUrl = prefs.getString("uploadUrl") ?? _uploadUrl;
    _companyDbUrl = prefs.getString("companyDbUrl") ?? _companyDbUrl;
    _deliveryUrl = prefs.getString("deliveryUrl") ?? _deliveryUrl;
    _routeOrderUrl = prefs.getString("routeOrderUrl") ?? _routeOrderUrl;

    // Then try to load JSON app settings file
    try {
      final fileSettings = await StorageService().loadAppSettingsFile();
      if (fileSettings.isNotEmpty) {
        _appMode = fileSettings['appMode'] ?? _appMode;
        _selectedRoute = fileSettings['selectedRoute'] ?? _selectedRoute;
        _selectedCompany = fileSettings['selectedCompany'] ?? _selectedCompany;
        _driverId = fileSettings['driverId'] ?? _driverId;
        _uploadUrl = fileSettings['uploadUrl'] ?? _uploadUrl;
        _companyDbUrl = fileSettings['companyDbUrl'] ?? _companyDbUrl;
        _deliveryUrl = fileSettings['deliveryUrl'] ?? _deliveryUrl;
        _routeOrderUrl = fileSettings['routeOrderUrl'] ?? _routeOrderUrl;
        if (fileSettings['themeMode'] != null) {
          final idx = int.tryParse(fileSettings['themeMode'].toString()) ?? fileSettings['themeMode'];
          if (idx is int && idx >= 0 && idx < ThemeMode.values.length) {
            _themeMode = ThemeMode.values[idx];
          }
        }
      }
    } catch (e) {
      print('Error reading app settings file: $e');
    }

    // Ensure driver id exists - but don't trigger saveSettings() if we're initializing
    if (_driverId.isEmpty) {
      _driverId = const Uuid().v4().substring(0, 8);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("driverId", _driverId);
      // Only save to settings file if we're not in the middle of initialization
      if (_shouldSaveSettings) {
        final settingsMap = {
          'driverId': _driverId,
        };
        await StorageService().saveAppSettingsFile(settingsMap);
      }
    }

    // Don't call notifyListeners() here - let it be called by initializeApp if needed
  }


  Future<void> saveSettings() async {
    if (!_shouldSaveSettings) return; // Don't save during initialization

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('appMode', _appMode);
      await prefs.setString('selectedRoute', _selectedRoute);
      await prefs.setString('selectedCompany', _selectedCompany);
      await prefs.setString('driverId', _driverId);
      await prefs.setInt('themeMode', _themeMode.index);

      await prefs.setString('uploadUrl', _uploadUrl);
      await prefs.setString('companyDbUrl', _companyDbUrl);
      await prefs.setString('deliveryUrl', _deliveryUrl);
      await prefs.setString('routeOrderUrl', _routeOrderUrl);

      print('✓ Saved to SharedPreferences');

      final settingsMap = {
        'appMode': _appMode,
        'selectedRoute': _selectedRoute,
        'selectedCompany': _selectedCompany,
        'driverId': _driverId,
        'themeMode': _themeMode.index,
        'uploadUrl': _uploadUrl,
        'companyDbUrl': _companyDbUrl,
        'deliveryUrl': _deliveryUrl,
        'routeOrderUrl': _routeOrderUrl,
      };

      await StorageService().saveAppSettingsFile(settingsMap);
      print('✓ Settings saved successfully');
    } catch (e) {
      print('ERROR saving settings: $e');
    }
  }

  void updateCompanyNames() {
    final route_data = _companyDatabase[_selectedRoute];

    if (route_data == null) {
      _companyNames = [];
    } else {
      _companyNames = route_data.companies.keys.toList()..sort();
    }

    notifyListeners();
  }

  Future<void> syncCompanyDatabaseOnStartup() async {
    if (_companyDbUrl.isEmpty) return;

    try {
      final serverData = await ApiService().fetchCompanyDatabase(_companyDbUrl);
      final converted = <String, RouteCompanies>{};

      serverData.forEach((route, companiesData) {
        final companiesMap = <String, Company>{};

        if (companiesData is Map<String, dynamic>) {
          companiesData.forEach((companyName, data) {
            List<String> descriptions = [];

            if (data is Map<String, dynamic>) {
              final raw = data['descriptions'] ?? data['frequent_blades'] ?? data['frequentBlades'];
              if (raw is List) {
                descriptions = raw.map((e) => e.toString()).toList();
              }
            }

            companiesMap[companyName] = Company(name: companyName, frequentBlades: descriptions);
          });
        }

        converted[route] = RouteCompanies(routeName: route, companies: companiesMap);
      });

      // Merge into existing database
      converted.forEach((route, routeCompanies) {
        if (!_companyDatabase.containsKey(route)) {
          _companyDatabase[route] = RouteCompanies(routeName: route, companies: {});
        }

        routeCompanies.companies.forEach((companyName, company) {
          if (_companyDatabase[route]!.companies.containsKey(companyName)) {
            final existing = _companyDatabase[route]!.companies[companyName]!;
            final merged = <String>{...existing.frequentBlades, ...company.frequentBlades}.toList();
            _companyDatabase[route]!.companies[companyName] = Company(name: companyName, frequentBlades: merged);
          } else {
            _companyDatabase[route]!.companies[companyName] = company;
          }
        });
      });

      // Save merged results
      await StorageService().saveCompanyDatabase(_companyDatabase);
      _updateAvailableRoutesFromCompanyDb();
      notifyListeners();
    } catch (e) {
      print('Startup company DB sync failed: $e');
    }
  }

  Future<void> loadCompanyDatabase() async {
    try {
      _companyDatabase = await StorageService().loadCompanyDatabase();
      _updateAvailableRoutesFromCompanyDb();

      // Ensure selectedCompany is still valid for selectedRoute
      if (_selectedRoute.isNotEmpty) {
        final routeData = _companyDatabase[_selectedRoute];
        if (routeData == null || !routeData.companies.containsKey(_selectedCompany)) {
          _selectedCompany = '';
          await saveSettings();
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading company database: $e');
      _companyDatabase = {};
      _availableRoutes = [];
      _companyNames = [];
      notifyListeners();
    }
  }

  Future<void> loadDeliveryData() async {
    try {
      _deliveryData = await StorageService().loadDeliveryData();
      _currentDeliveryIndex = 0;
      notifyListeners();
    } catch (e) {
      print('Error loading delivery data: $e');
      _deliveryData = null;
      notifyListeners();
    }
  }

  Future<void> loadRouteOrderCache() async {
    try {
      final cache = await StorageService().loadRouteOrderCache();
      // If a selected route exists, load cached stops for it
      if (_selectedRoute.isNotEmpty && cache.containsKey(_selectedRoute)) {
        _routeOrderStops = cache[_selectedRoute]!;
      } else {
        _routeOrderStops = [];
      }
      _routeOrderCurrentIndex = 0;
      notifyListeners();
    } catch (e) {
      print('Error loading route order cache: $e');
      _routeOrderStops = [];
      notifyListeners();
    }
  }

  void _updateAvailableRoutesFromCompanyDb() {
    _availableRoutes = _companyDatabase.keys.toList();
    if (_availableRoutes.isEmpty) {
      _availableRoutes = ['Route 1', 'Route 2', 'Route 3'];
    }
  }

  // Switch between modes
  void switchToPickupMode() {
    _appMode = 'pickup';
    saveSettings();
    notifyListeners();
  }

  void switchToDeliveryMode() {
    _appMode = 'delivery';
    saveSettings();
    notifyListeners();
  }

  // Navigation helpers
  void navigateToPickupHome() {
    _appMode = 'pickup';
    saveSettings();
    notifyListeners();
  }

  void navigateToDeliveryHome() {
    _appMode = 'delivery';
    saveSettings();
    notifyListeners();
  }

  // Update URLs
  void updateUrls({
    String? uploadUrl,
    String? companyDbUrl,
    String? deliveryUrl,
    String? routeOrderUrl,
  }) {
    _uploadUrl = uploadUrl ?? _uploadUrl;
    _companyDbUrl = companyDbUrl ?? _companyDbUrl;
    _deliveryUrl = deliveryUrl ?? _deliveryUrl;
    _routeOrderUrl = routeOrderUrl ?? _routeOrderUrl;
    saveSettings();
    notifyListeners();
  }

  // Delivery navigation
  void nextDelivery() {
    if (_deliveryData != null && _currentDeliveryIndex < _deliveryData!.companies.length - 1) {
      _currentDeliveryIndex++;
      notifyListeners();
    }
  }

  void previousDelivery() {
    if (_currentDeliveryIndex > 0) {
      _currentDeliveryIndex--;
      notifyListeners();
    }
  }

  void setDeliveryIndex(int index) {
    if (_deliveryData != null && index >= 0 && index < _deliveryData!.companies.length) {
      _currentDeliveryIndex = index;
      notifyListeners();
    }
  }

  // Route order navigation
  void nextRouteStop() {
    if (_routeOrderCurrentIndex < _routeOrderStops.length - 1) {
      _routeOrderCurrentIndex++;
      notifyListeners();
    }
  }

  void previousRouteStop() {
    if (_routeOrderCurrentIndex > 0) {
      _routeOrderCurrentIndex--;
      notifyListeners();
    }
  }

  void setRouteOrderViewMode(String mode) {
    _routeOrderViewMode = mode;
    saveSettings();
    notifyListeners();
  }

  void setRouteOrderIndex(int index) {
    if (index >= 0 && index < _routeOrderStops.length) {
      _routeOrderCurrentIndex = index;
      notifyListeners();
    }
  }
}

