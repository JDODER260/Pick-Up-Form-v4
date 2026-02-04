import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pickup_delivery_app/models/delivery_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';

class DeliveryProvider with ChangeNotifier {
  DeliveryData? _deliveryData;
  int _currentIndex = 0;
  Map<String, Map<int, Map<String, dynamic>>> _bladeEdits = {};

  DeliveryData? get deliveryData => _deliveryData;
  int get currentIndex => _currentIndex;
  int get totalDeliveries => _deliveryData?.companies.length ?? 0;

  DeliveryCompany? get currentCompany {
    if (_deliveryData != null && _currentIndex < _deliveryData!.companies.length) {
      return _deliveryData!.companies[_currentIndex];
    }
    return null;
  }

  // Load delivery data
  Future<void> loadDeliveryData() async {
    try {
      _deliveryData = await StorageService().loadDeliveryData();
      _currentIndex = 0;
      _bladeEdits.clear();
      notifyListeners();
    } catch (e) {
      print('Error loading delivery data: $e');
      _deliveryData = null;
      notifyListeners();
    }
  }

  // Save delivery data
  Future<void> saveDeliveryData() async {
    if (_deliveryData != null) {
      await StorageService().saveDeliveryData(_deliveryData!);
    }
  }

  // Set delivery data
  void setDeliveryData(DeliveryData data) {
    _deliveryData = data;
    _currentIndex = 0;
    _bladeEdits.clear();
    notifyListeners();
  }

  // Navigation
  void nextDelivery() {
    if (_deliveryData != null && _currentIndex < _deliveryData!.companies.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousDelivery() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setDeliveryIndex(int index) {
    if (_deliveryData != null && index >= 0 && index < _deliveryData!.companies.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Edit blade details
  void editBladeDetails(String companyName, int poIndex, Map<String, dynamic> details) {
    if (!_bladeEdits.containsKey(companyName)) {
      _bladeEdits[companyName] = {};
    }
    _bladeEdits[companyName]![poIndex] = details;

    // Apply to delivery data
    if (_deliveryData != null) {
      final companyIndex = _deliveryData!.companies.indexWhere((c) => c.companyName == companyName);
      if (companyIndex >= 0 && poIndex < _deliveryData!.companies[companyIndex].poList.length) {
        final po = _deliveryData!.companies[companyIndex].poList[poIndex];
        final updatedPO = DeliveryPO(
          poNumber: po.poNumber,
          description: po.description,
          quantity: po.quantity,
          pickupDate: po.pickupDate,
          expectedDelivery: po.expectedDelivery,
          bladeDetails: details,
        );
        _deliveryData!.companies[companyIndex].poList[poIndex] = updatedPO;
      }
    }

    notifyListeners();
  }

  // Save blade edits
  Future<void> saveBladeEdits() async {
    await saveDeliveryData();
  }

  // Get blade details for editing
  Map<String, dynamic> getBladeDetailsForEditing(String companyName, int poIndex) {
    if (_bladeEdits.containsKey(companyName) && _bladeEdits[companyName]!.containsKey(poIndex)) {
      return _bladeEdits[companyName]![poIndex]!;
    }

    // Return from current data
    if (_deliveryData != null) {
      final companyIndex = _deliveryData!.companies.indexWhere((c) => c.companyName == companyName);
      if (companyIndex >= 0 && poIndex < _deliveryData!.companies[companyIndex].poList.length) {
        return _deliveryData!.companies[companyIndex].poList[poIndex].bladeDetails;
      }
    }

    return {};
  }

  // Get company index by name
  int getCompanyIndexByName(String companyName) {
    if (_deliveryData != null) {
      for (int i = 0; i < _deliveryData!.companies.length; i++) {
        if (_deliveryData!.companies[i].companyName == companyName) {
          return i;
        }
      }
    }
    return -1;
  }
}