import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/company_provider.dart';
import 'package:pickup_delivery_app/screens/company/company_management_screen.dart';
import 'package:pickup_delivery_app/screens/company/company_selection_screen.dart';
import 'package:pickup_delivery_app/services/update_manager.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _uploadUrlController = TextEditingController();
  final _companyDbUrlController = TextEditingController();
  final _deliveryUrlController = TextEditingController();
  final _routeOrderUrlController = TextEditingController();
  final _registerFcmUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    _uploadUrlController.text = appProvider.uploadUrl;
    _companyDbUrlController.text = appProvider.companyDbUrl;
    _deliveryUrlController.text = appProvider.deliveryUrl;
    _routeOrderUrlController.text = appProvider.routeOrderUrl;
    _registerFcmUrlController.text = appProvider.registerFcmUrl;
  }

  @override
  void dispose() {
    _uploadUrlController.dispose();
    _companyDbUrlController.dispose();
    _deliveryUrlController.dispose();
    _routeOrderUrlController.dispose();
    _registerFcmUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    appProvider.updateUrls(
      uploadUrl: _uploadUrlController.text.trim(),
      companyDbUrl: _companyDbUrlController.text.trim(),
      deliveryUrl: _deliveryUrlController.text.trim(),
      routeOrderUrl: _routeOrderUrlController.text.trim(),
      registerFcmUrl: _registerFcmUrlController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await UpdateManager().checkAndUpdate(
      context,
      updateCheckUrl: appProvider.updateCheckUrl,
      currentVersion: appProvider.currentVersion,
    );
  }

  Future<void> _showSyncDialogAndRun() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final companyProvider =
        Provider.of<CompanyProvider>(context, listen: false);

    if (appProvider.companyDbUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company DB URL is not set')),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sync Company Database'),
        content: Text(
            'Choose how to sync with the server:\n\nMerge: keep existing entries and add new ones.\nReplace: overwrite local database with server database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('merge'),
            child: Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('replace'),
            child: Text('Replace'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          // ignore: deprecated_member_use
          WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Syncing company database...')),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await companyProvider.syncWithServer(
      appProvider.companyDbUrl,
      replace: choice == 'replace',
    );

    Navigator.of(context).pop(); // close progress dialog

    if (success) {
      // Refresh app provider company DB so UI reflects new routes/companies
      await appProvider.loadCompanyDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Company database synced successfully'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to sync company database'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default App Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              appProvider.appMode = 'delivery';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appProvider.appMode == 'delivery'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                            child: Text('Delivery Mode'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              appProvider.appMode = 'pickup';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appProvider.appMode == 'pickup'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                            child: Text('Pickup Mode'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Theme
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownButton<ThemeMode>(
                      value: appProvider.themeMode,
                      onChanged: (ThemeMode? newValue) {
                        if (newValue != null) {
                          appProvider.themeMode = newValue;
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Company Database
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company Database',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanyManagementScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.business),
                      label: Text('Manage Company Database'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showSyncDialogAndRun,
                      icon: Icon(Icons.sync),
                      label: Text('Sync with Server'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CompanySelectionScreen()),
                        );
                      },
                      icon: Icon(Icons.business_center),
                      label: Text('Select Company'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 44),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Last Synced: ' +
                        Provider.of<CompanyProvider>(context).lastSyncText),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // App Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Driver ID:', appProvider.driverId),
                    _buildInfoRow('Current Route:', appProvider.selectedRoute),
                    _buildInfoRow(
                        'Current Company:', appProvider.selectedCompany),
                    _buildInfoRow('App Version:', appProvider.currentVersion),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Update Check
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Updates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _checkForUpdates,
                      icon: Icon(Icons.update),
                      label: Text('Check for Updates'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // URL Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API URLs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _uploadUrlController,
                      decoration: InputDecoration(
                        labelText: 'Upload URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _companyDbUrlController,
                      decoration: InputDecoration(
                        labelText: 'Database URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _deliveryUrlController,
                      decoration: InputDecoration(
                        labelText: 'Delivery API URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _routeOrderUrlController,
                      decoration: InputDecoration(
                        labelText: 'Route Order URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _registerFcmUrlController,
                      decoration: InputDecoration(
                        labelText: 'FCM Register URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: Icon(Icons.save),
                      label: Text('Save URL Settings'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'Not set'),
          ),
        ],
      ),
    );
  }
}
