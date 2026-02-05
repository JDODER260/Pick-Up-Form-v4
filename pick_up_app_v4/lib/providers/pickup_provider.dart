import 'package:flutter/material.dart';
import 'package:pickup_delivery_app/models/po_model.dart';
import 'package:pickup_delivery_app/services/storage_service.dart';
import 'package:pickup_delivery_app/services/api_service.dart';

class PickupProvider with ChangeNotifier {
  List<PickupOrder> _pos = [];
  List<int> _selectedIndices = [];
  int? _editingIndex;

  List<PickupOrder> get pos => _pos;
  List<int> get selectedIndices => _selectedIndices;
  int? get editingIndex => _editingIndex;

  // Load POs
  Future<void> loadPOs() async {
    try {
      _pos = await StorageService().loadPOData();
      _selectedIndices.clear();
      notifyListeners();
    } catch (e) {
      print('Error loading POs: $e');
      _pos = [];
      notifyListeners();
    }
  }

  // Save POs
  Future<void> savePOs() async {
    await StorageService().savePOData(_pos);
  }

  // Add PO
  Future<void> addPO(PickupOrder po) async {
    _pos.add(po);
    await savePOs();
    notifyListeners();
  }

  // Update PO
  Future<void> updatePO(int index, PickupOrder po) async {
    if (index >= 0 && index < _pos.length) {
      _pos[index] = po;
      await savePOs();
      notifyListeners();
    }
  }

  // Delete PO
  Future<void> deletePO(int index) async {
    if (index >= 0 && index < _pos.length) {
      _pos.removeAt(index);
      await savePOs();
      notifyListeners();
    }
  }

  // Delete selected POs
  Future<void> deleteSelected() async {
    // Sort in descending order to avoid index issues
    _selectedIndices.sort((a, b) => b.compareTo(a));

    for (var index in _selectedIndices) {
      if (index >= 0 && index < _pos.length) {
        _pos.removeAt(index);
      }
    }

    _selectedIndices.clear();
    await savePOs();
    notifyListeners();
  }

  // Select/Deselect PO
  void toggleSelection(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  // Select all POs
  void selectAll() {
    _selectedIndices = List.generate(_pos.length, (index) => index);
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedIndices.clear();
    notifyListeners();
  }

  // Set editing index
  void setEditingIndex(int? index) {
    _editingIndex = index;
    notifyListeners();
  }

  // Get PO for editing
  PickupOrder? getPOForEditing() {
    if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < _pos.length) {
      return _pos[_editingIndex!];
    }
    return null;
  }

  // Upload selected POs
  Future<void> uploadSelected(String uploadUrl) async {
    final selectedPOs = _selectedIndices
        .where((index) => index >= 0 && index < _pos.length)
        .map((index) => _pos[index])
        .toList();

    if (selectedPOs.isEmpty) return;

    // Prepare payload matching server contract
    final payload = selectedPOs.map((po) {
      // Format pickup_date as MM/DD/YYYY
      final pickupDateStr = '${po.pickupDate.month.toString().padLeft(2, '0')}/${po.pickupDate.day.toString().padLeft(2, '0')}/${po.pickupDate.year}';

      return {
        'uploaded': true,
        'description': po.description,
        'company': po.company,
        'route': po.route,
        'quantity': po.quantity.toString(),
        'pickup_date': pickupDateStr,
        'driver_id': po.driverId,
        'created_at': po.createdAt.toIso8601String(),
      };
    }).toList();

    try {
      await ApiService().uploadPOs(payload.cast<Map<String, dynamic>>(), uploadUrl);

      // If upload succeeded (HTTP 200), mark uploaded true locally
      // The server returns HTTP 200 on success per contract
      for (var index in _selectedIndices) {
        if (index >= 0 && index < _pos.length) {
          _pos[index] = _pos[index].copyWith(uploaded: true, updatedAt: DateTime.now());
        }
      }

      await savePOs();
      clearSelection();
      notifyListeners();
    } catch (e) {
      print('Failed to upload POs: $e');
      // Keep local state; rethrow so UI can display the error to the user
      rethrow;
    }
  }

  // Check if all are selected
  bool get allSelected {
    return _pos.isNotEmpty && _selectedIndices.length == _pos.length;
  }

  // Get selected count
  int get selectedCount => _selectedIndices.length;
}