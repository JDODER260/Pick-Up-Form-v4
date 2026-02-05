import 'package:flutter/material.dart';
import 'package:pickup_delivery_app/models/route_order_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';

class RouteOrderProvider with ChangeNotifier {
  List<RouteStop> _stops = [];
  int _currentIndex = 0;
  String _viewMode = 'overview'; // 'overview' or 'single'

  List<RouteStop> get stops => _stops.where((stop) => stop.show).toList();
  int get currentIndex => _currentIndex;
  String get viewMode => _viewMode;
  RouteStop? get currentStop => stops.isNotEmpty && _currentIndex < stops.length
      ? stops[_currentIndex]
      : null;

  // Load route order cache
  Future<void> loadRouteOrderCache([String? route]) async {
    try {
      final cache = await StorageService().loadRouteOrderCache();
      if (route != null && cache.containsKey(route)) {
        _stops = cache[route]!;
      } else {
        _stops = [];
      }
      _currentIndex = 0;
      notifyListeners();
    } catch (e) {
      print('Error loading route order cache: $e');
      _stops = [];
      notifyListeners();
    }
  }

  // Save route order cache
  Future<void> saveRouteOrderCache(String route) async {
    try {
      final cache = await StorageService().loadRouteOrderCache();
      cache[route] = _stops;
      await StorageService().saveRouteOrderCache(cache);
    } catch (e) {
      print('Error saving route order cache: $e');
    }
  }

  // Set route stops
  void setRouteStops(List<RouteStop> stops, String route) {
    _stops = stops;
    _currentIndex = 0;
    // Sort by sortNum
    _stops.sort((a, b) {
      try {
        final aNum = int.tryParse(a.sortNum) ?? 0;
        final bNum = int.tryParse(b.sortNum) ?? 0;
        return aNum.compareTo(bNum);
      } catch (e) {
        return a.displayName.compareTo(b.displayName);
      }
    });

    saveRouteOrderCache(route);
    notifyListeners();
  }

  // Set view mode
  void setViewMode(String mode) {
    _viewMode = mode;
    notifyListeners();
  }

  // Navigation
  void nextStop() {
    if (_currentIndex < stops.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousStop() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setStopIndex(int index) {
    if (index >= 0 && index < stops.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Get stop by index
  RouteStop? getStop(int index) {
    if (index >= 0 && index < stops.length) {
      return stops[index];
    }
    return null;
  }

  // Check if navigation is available
  bool get hasNext => _currentIndex < stops.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  // Get stop display text
  String get currentStopText {
    if (stops.isEmpty) return 'No stops loaded';
    return '${_currentIndex + 1} of ${stops.length}';
  }
}
