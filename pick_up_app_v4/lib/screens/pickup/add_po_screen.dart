import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/pickup_provider.dart';
import 'package:pickup_delivery_app/providers/company_provider.dart';
import 'package:pickup_delivery_app/models/po_model.dart';

class AddPOScreen extends StatefulWidget {
  @override
  _AddPOScreenState createState() => _AddPOScreenState();
}

class _AddPOScreenState extends State<AddPOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customDescriptionController = TextEditingController();

  String? _selectedBlade;
  bool _useCustomDescription = false;

  @override
  void initState() {
    super.initState();
    _loadEditingData();
  }

  void _loadEditingData() {
    final pickupProvider = Provider.of<PickupProvider>(context, listen: false);
    final editingPO = pickupProvider.getPOForEditing();

    if (editingPO != null) {
      _descriptionController.text = editingPO.description;
      _quantityController.text = editingPO.quantity.toString();

      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final blades = companyProvider.getFrequentBlades(
        editingPO.route,
        editingPO.company,
      );

      if (blades.contains(editingPO.description)) {
        _selectedBlade = editingPO.description;
        _useCustomDescription = false;
      } else {
        _useCustomDescription = true;
        _customDescriptionController.text = editingPO.description;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _customDescriptionController.dispose();
    super.dispose();
  }

  // Updated effective description logic:
  // - Prefer an explicit custom description if present (non-empty)
  // - Fallback to selected blade if available
  // - Return empty string if none provided
  String get _effectiveDescription {
    final custom = _customDescriptionController.text.trim();
    if (custom.isNotEmpty) {
      return custom;
    }
    if (_useCustomDescription) {
      // If user toggled to custom but left it empty, return empty to fail validation
      return '';
    }
    return _selectedBlade ?? '';
  }

  Future<void> _savePO() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure we have a description (either selected or custom)
    if (_effectiveDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a description (select a frequent blade or enter a custom description)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final pickupProvider = Provider.of<PickupProvider>(context, listen: false);

    if (appProvider.selectedRoute.isEmpty || appProvider.selectedCompany.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select route and company first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final existingIndex = pickupProvider.editingIndex;
    final existingPO = existingIndex != null && existingIndex >= 0 && existingIndex < pickupProvider.pos.length
        ? pickupProvider.pos[existingIndex]
        : null;

    final po = PickupOrder(
      id: existingPO?.id ?? const Uuid().v4(),
      description: _effectiveDescription,
      company: appProvider.selectedCompany,
      route: appProvider.selectedRoute,
      quantity: quantity,
      pickupDate: DateTime.now(),
      driverId: appProvider.driverId,
      uploaded: existingPO?.uploaded ?? false,
      bladeDetails: existingPO?.bladeDetails ?? {},
      createdAt: existingPO?.createdAt ?? DateTime.now(),
    );

    if (pickupProvider.editingIndex != null) {
      await pickupProvider.updatePO(pickupProvider.editingIndex!, po);
    } else {
      await pickupProvider.addPO(po);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PO saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context);

    final frequentBlades = companyProvider.getFrequentBlades(
      appProvider.selectedRoute,
      appProvider.selectedCompany,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Pickup Order'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route: ${appProvider.selectedRoute}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Company: ${appProvider.selectedCompany}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Description Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Frequent blades dropdown
                      if (frequentBlades.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _useCustomDescription ? null : _selectedBlade,
                          items: [
                            ...frequentBlades.map((blade) {
                              return DropdownMenuItem(
                                value: blade,
                                child: Text(blade),
                              );
                            }).toList(),
                            DropdownMenuItem(
                              value: '_custom',
                              child: Text('--- Enter Custom Description ---'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value == '_custom') {
                                _useCustomDescription = true;
                                _selectedBlade = null;
                                // Keep any previously typed custom description
                              } else {
                                _useCustomDescription = false;
                                _selectedBlade = value;
                                // If user picks a frequent blade, clear custom field to avoid stale text
                                _customDescriptionController.clear();
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Frequent Blades',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_useCustomDescription && (value == null || value.isEmpty)) {
                              return 'Please select a description';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                      ],

                      // Custom description
                      if (_useCustomDescription || frequentBlades.isEmpty)
                        TextFormField(
                          controller: _customDescriptionController,
                          decoration: InputDecoration(
                            labelText: 'Custom Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (_useCustomDescription && (value == null || value.trim().isEmpty)) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Quantity and Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity & Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),

                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity Received',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num <= 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Pickup Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        initialValue: '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Save Button
              ElevatedButton.icon(
                onPressed: _savePO,
                icon: Icon(Icons.save),
                label: Text('Save PO'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),

              SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}