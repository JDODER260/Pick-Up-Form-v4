import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pickup_delivery_app/models/company_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';
import 'package:pickup_delivery_app/services/api_service.dart';

import '../app/app_constants.dart';

class CompanyProvider with ChangeNotifier {
  // Use LinkedHashMap to preserve insertion order
  final Map<String, RouteCompanies> _companyDatabase = {};
  bool _isLoading = false;
  bool _isLoaded = false;
  String _selectedRoute = '';
  String _selectedCompany = '';
  List<String> _availableRoutes = [];
  List<String> _companyNames = [];
  List<String> _companyNamesUnsorted = []; // Keep unsorted version

  bool _isSyncing = false;
  DateTime? _lastSync;

  Map<String, RouteCompanies> get companyDatabase => _companyDatabase;
  String get selectedRoute => _selectedRoute;
  String get selectedCompany => _selectedCompany;
  List<String> get availableRoutes => _availableRoutes;
  List<String> get companyNames => _companyNamesUnsorted; // Return unsorted
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;
  String get lastSyncText => _lastSync != null
      ? 'Last sync: ${_lastSync!.toLocal().toString().substring(0, 16)}'
      : 'Never synced';

  // Load company database
  Future<void> loadCompanyDatabase() async {
    if (_isLoaded || _isLoading) {
      return;
    }

    _isLoading = true;

    try {
      final loadedData = await StorageService().loadCompanyDatabase();
      _companyDatabase.clear();
      _companyDatabase.addAll(loadedData);

      _updateAvailableRoutes();
      _updateCompanyNames();

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString("company_last_sync");
      if (last != null && last.isNotEmpty) {
        try {
          _lastSync = DateTime.parse(last);
        } catch (_) {
          _lastSync = null;
        }
      }

      // Load selected company if exists
      final savedCompany = prefs.getString('selected_company');
      if (savedCompany != null && savedCompany.isNotEmpty) {
        _selectedCompany = savedCompany;
      }

      _isLoaded = true;
    } catch (e) {
      print("Error loading company database: $e");
      _companyDatabase.clear();
      _availableRoutes = [];
      _companyNames = [];
      _companyNamesUnsorted = [];
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save company database
  Future<void> saveCompanyDatabase() async {
    await StorageService().saveCompanyDatabase(_companyDatabase);
    _updateAvailableRoutes();
    _updateCompanyNames();
    notifyListeners();
  }

  // Update route lists
  void _updateAvailableRoutes() {
    _availableRoutes = _companyDatabase.keys.toList();
    // Add default routes if none exist
    if (_availableRoutes.isEmpty) {
      _availableRoutes = AppConstants.defaultRoutes;
    }
  }

  // Update company names for selected route
  void _updateCompanyNames() {
    if (_selectedRoute.isNotEmpty && _companyDatabase.containsKey(_selectedRoute)) {
      // Keep original insertion order
      _companyNamesUnsorted = _companyDatabase[_selectedRoute]!.companies.keys.toList();
      // Create sorted version for UI if needed elsewhere
      _companyNames = List.from(_companyNamesUnsorted)..sort();
    } else {
      _companyNamesUnsorted = [];
      _companyNames = [];
    }
  }

  // Set selected route
  void setSelectedRoute(String route) {
    if (_selectedRoute != route) {
      _selectedRoute = route;
      _selectedCompany = '';
      _updateCompanyNames();

      // Save to preferences
      _saveSelectedRoute();
      notifyListeners();
    }
  }

  // Set selected company
  void setSelectedCompany(String company) {
    if (_selectedCompany != company) {
      _selectedCompany = company;
      // Save persistently
      _saveSelectedCompany();
      notifyListeners();
    }
  }

  // Add route (preserves order)
  void addRoute(String routeName) {
    if (!_companyDatabase.containsKey(routeName)) {
      _companyDatabase[routeName] = RouteCompanies(
        routeName: routeName,
        companies: {},
      );
      saveCompanyDatabase();
    }
  }

  // Delete route
  void deleteRoute(String routeName) {
    if (_companyDatabase.containsKey(routeName)) {
      _companyDatabase.remove(routeName);
      if (_selectedRoute == routeName) {
        _selectedRoute = '';
        _selectedCompany = '';
        _saveSelectedRoute();
        _saveSelectedCompany();
      }
      saveCompanyDatabase();
    }
  }

  // Add company to route (appends to end)
  void addCompany(String routeName, String companyName) {
    if (_companyDatabase.containsKey(routeName)) {
      _companyDatabase[routeName]!.companies[companyName] = Company(
        name: companyName,
        frequentBlades: [],
      );
      saveCompanyDatabase();
    }
  }

  // Delete company from route
  void deleteCompany(String routeName, String companyName) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(companyName)) {
      _companyDatabase[routeName]!.companies.remove(companyName);
      if (_selectedCompany == companyName && _selectedRoute == routeName) {
        _selectedCompany = '';
        _saveSelectedCompany();
      }
      saveCompanyDatabase();
    }
  }

  // Add frequent blade to company
  void addFrequentBlade(String routeName, String companyName, String blade) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(companyName)) {
      final company = _companyDatabase[routeName]!.companies[companyName]!;
      if (!company.frequentBlades.contains(blade)) {
        company.frequentBlades.add(blade);
        saveCompanyDatabase();
      }
    }
  }

  // Delete frequent blade from company
  void deleteFrequentBlade(String routeName, String companyName, String blade) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(companyName)) {
      final company = _companyDatabase[routeName]!.companies[companyName]!;
      company.frequentBlades.remove(blade);
      saveCompanyDatabase();
    }
  }

  // Get frequent blades for company
  List<String> getFrequentBlades(String routeName, String companyName) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(companyName)) {
      return _companyDatabase[routeName]!.companies[companyName]!.frequentBlades;
    }
    return [];
  }

  // Get list of companies for a route in INSERTION ORDER
  List<String> getCompaniesForRoute(String routeName) {
    if (_companyDatabase.containsKey(routeName)) {
      // Return in original insertion order
      return _companyDatabase[routeName]!.companies.keys.toList();
    }
    return [];
  }

  // Get SORTED list of companies (for UI when needed)
  List<String> getSortedCompaniesForRoute(String routeName) {
    if (_companyDatabase.containsKey(routeName)) {
      final companies = _companyDatabase[routeName]!.companies.keys.toList();
      companies.sort();
      return companies;
    }
    return [];
  }

  // Rename route
  void renameRoute(String oldName, String newName) {
    if (_companyDatabase.containsKey(oldName) && !_companyDatabase.containsKey(newName)) {
      final companies = _companyDatabase[oldName]!;
      _companyDatabase.remove(oldName);
      _companyDatabase[newName] = companies;

      if (_selectedRoute == oldName) {
        _selectedRoute = newName;
        _saveSelectedRoute();
      }

      saveCompanyDatabase();
    }
  }

  // Rename company (preserves position)
  void renameCompany(String routeName, String oldName, String newName) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(oldName) &&
        !_companyDatabase[routeName]!.companies.containsKey(newName)) {

      // Get the company data
      final company = _companyDatabase[routeName]!.companies[oldName]!;

      // Create new map to preserve order
      final newCompanies = <String, Company>{};
      final companies = _companyDatabase[routeName]!.companies;

      for (var entry in companies.entries) {
        if (entry.key == oldName) {
          newCompanies[newName] = Company(
            name: newName,
            frequentBlades: company.frequentBlades,
          );
        } else {
          newCompanies[entry.key] = entry.value;
        }
      }

      _companyDatabase[routeName]!.companies.clear();
      _companyDatabase[routeName]!.companies.addAll(newCompanies);

      if (_selectedCompany == oldName && _selectedRoute == routeName) {
        _selectedCompany = newName;
        _saveSelectedCompany();
      }

      saveCompanyDatabase();
    }
  }

  // Sync with server
  Future<bool> syncWithServer(String apiUrl, {bool replace = false}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      print('Syncing company database with $apiUrl');
      final serverData = await ApiService().fetchCompanyDatabase(apiUrl);

      final converted = <String, RouteCompanies>{};

      serverData.forEach((route, companiesData) {
        final companiesMap = <String, Company>{};

        if (companiesData is Map<String, dynamic>) {
          companiesData.forEach((companyName, data) {
            List<String> descriptions = [];

            if (data is Map<String, dynamic>) {
              final raw = data['descriptions'];
              if (raw is List) {
                descriptions = raw.map((e) => e.toString()).toList();
              }
            }

            companiesMap[companyName] = Company(
              name: companyName,
              frequentBlades: descriptions,
            );
          });
        }

        converted[route] = RouteCompanies(routeName: route, companies: companiesMap);
      });

      if (replace) {
        _companyDatabase.clear();
        _companyDatabase.addAll(converted);
      } else {
        // Merge preserving existing order for existing companies
        converted.forEach((route, routeCompanies) {
          if (!_companyDatabase.containsKey(route)) {
            _companyDatabase[route] = RouteCompanies(routeName: route, companies: {});
          }

          // Add new companies to the end
          routeCompanies.companies.forEach((companyName, company) {
            if (!_companyDatabase[route]!.companies.containsKey(companyName)) {
              _companyDatabase[route]!.companies[companyName] = company;
            } else {
              // Merge frequent blades for existing companies
              final existing = _companyDatabase[route]!.companies[companyName]!;
              final merged = <String>{...existing.frequentBlades, ...company.frequentBlades}.toList();
              _companyDatabase[route]!.companies[companyName] =
                  Company(name: companyName, frequentBlades: merged);
            }
          });
        });
      }

      await saveCompanyDatabase();
      _updateAvailableRoutes();
      _updateCompanyNames();

      // Update last sync
      _lastSync = DateTime.now().toUtc();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_last_sync', _lastSync!.toIso8601String());

      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e, st) {
      print('Error syncing company database: $e');
      print(st);
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // Move to next company in the current route (in insertion order)
  Future<void> selectNextCompany() async {
    if (_companyNamesUnsorted.isEmpty || _selectedRoute.isEmpty) {
      return;
    }

    // If no company selected, start with first
    if (_selectedCompany.isEmpty) {
      if (_companyNamesUnsorted.isNotEmpty) {
        _selectedCompany = _companyNamesUnsorted.first;
        await _saveSelectedCompany();
        notifyListeners();
      }
      return;
    }

    int currentIndex = _companyNamesUnsorted.indexOf(_selectedCompany);

    // If company not found or is last, go to first
    if (currentIndex == -1 || currentIndex == _companyNamesUnsorted.length - 1) {
      _selectedCompany = _companyNamesUnsorted.first;
    } else {
      _selectedCompany = _companyNamesUnsorted[currentIndex + 1];
    }

    await _saveSelectedCompany();
    notifyListeners();
  }

  // Move to previous company
  Future<void> selectPreviousCompany() async {
    if (_companyNamesUnsorted.isEmpty || _selectedRoute.isEmpty) {
      return;
    }

    if (_selectedCompany.isEmpty) {
      if (_companyNamesUnsorted.isNotEmpty) {
        _selectedCompany = _companyNamesUnsorted.last;
        await _saveSelectedCompany();
        notifyListeners();
      }
      return;
    }

    int currentIndex = _companyNamesUnsorted.indexOf(_selectedCompany);

    if (currentIndex == -1 || currentIndex == 0) {
      _selectedCompany = _companyNamesUnsorted.last;
    } else {
      _selectedCompany = _companyNamesUnsorted[currentIndex - 1];
    }

    await _saveSelectedCompany();
    notifyListeners();
  }

  // Get small label like "4 out of 17"
  String getSelectedCompanyLabel() {
    if (_companyNamesUnsorted.isEmpty || _selectedCompany.isEmpty) {
      return 'No company selected';
    }

    int index = _companyNamesUnsorted.indexOf(_selectedCompany);
    if (index == -1) {
      return 'Company not found';
    }

    int total = _companyNamesUnsorted.length;
    return '${index + 1} of $total';
  }

  // Save selected company to SharedPreferences
  Future<void> _saveSelectedCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_company', _selectedCompany);
    } catch (e) {
      print('⚠️ Failed to save selected company: $e');
    }
  }

  // Save selected route to SharedPreferences
  Future<void> _saveSelectedRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_route', _selectedRoute);
    } catch (e) {
      print('⚠️ Failed to save selected route: $e');
    }
  }

  // Initialize with saved preferences
  Future<void> initializeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedRoute = prefs.getString('selected_route');
      final savedCompany = prefs.getString('selected_company');

      if (savedRoute != null && savedRoute.isNotEmpty) {
        _selectedRoute = savedRoute;
      }

      if (savedCompany != null && savedCompany.isNotEmpty) {
        _selectedCompany = savedCompany;
      }

      notifyListeners();
    } catch (e) {
      print('⚠️ Failed to load preferences: $e');
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    _companyDatabase.clear();
    _selectedRoute = '';
    _selectedCompany = '';
    _availableRoutes = [];
    _companyNames = [];
    _companyNamesUnsorted = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_route');
    await prefs.remove('selected_company');
    await prefs.remove('company_last_sync');

    notifyListeners();
  }
}