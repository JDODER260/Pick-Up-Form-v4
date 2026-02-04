import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pickup_delivery_app/models/company_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';
import 'package:pickup_delivery_app/services/api_service.dart';

import '../app/app_constants.dart';

class CompanyProvider with ChangeNotifier {
  Map<String, RouteCompanies> _companyDatabase = {};
  bool _is_loading = false;
  bool _is_loaded = false;
  String _selectedRoute = '';
  String _selectedCompany = '';
  List<String> _availableRoutes = [];
  List<String> _companyNames = [];

  bool _isSyncing = false;
  DateTime? _lastSync;

  Map<String, RouteCompanies> get companyDatabase => _companyDatabase;
  String get selectedRoute => _selectedRoute;
  String get selectedCompany => _selectedCompany;
  List<String> get availableRoutes => _availableRoutes;
  List<String> get companyNames => _companyNames;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;
  String get lastSyncText => _lastSync != null ? _lastSync!.toLocal().toString() : 'Never';

  // Load company database
  Future<void> loadCompanyDatabase() async {
    if (_is_loaded || _is_loading) {
      return;
    }

    _is_loading = true;

    try {
      _companyDatabase = await StorageService().loadCompanyDatabase();
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

      _is_loaded = true;
    } catch (e) {
      print("Error loading company database: $e");
      _companyDatabase = {};
      _availableRoutes = [];
      _companyNames = [];
      _is_loaded = true;
    } finally {
      _is_loading = false;
    }

    notifyListeners();
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
      _companyNames = _companyDatabase[_selectedRoute]!.companies.keys.toList();
    } else {
      _companyNames = [];
    }
    _companyNames.sort();
  }

  // Set selected route
  void setSelectedRoute(String route) {
    _selectedRoute = route;
    _updateCompanyNames();
    notifyListeners();
  }

  // Set selected company
  void setSelectedCompany(String company) {
    _selectedCompany = company;
    notifyListeners();
  }

  // Add route
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
      }
      saveCompanyDatabase();
    }
  }

  // Add company to route
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

  // Get list of companies for a route
  List<String> getCompaniesForRoute(String routeName) {
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
      }

      saveCompanyDatabase();
    }
  }

  // Rename company
  void renameCompany(String routeName, String oldName, String newName) {
    if (_companyDatabase.containsKey(routeName) &&
        _companyDatabase[routeName]!.companies.containsKey(oldName) &&
        !_companyDatabase[routeName]!.companies.containsKey(newName)) {

      final company = _companyDatabase[routeName]!.companies[oldName]!;
      _companyDatabase[routeName]!.companies.remove(oldName);
      _companyDatabase[routeName]!.companies[newName] = Company(
        name: newName,
        frequentBlades: company.frequentBlades,
      );

      if (_selectedCompany == oldName && _selectedRoute == routeName) {
        _selectedCompany = newName;
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
        _companyDatabase = converted;
      } else {
        // Merge
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
      }

      await saveCompanyDatabase();
      _updateAvailableRoutes();
      _updateCompanyNames();

      // update last sync
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
}
