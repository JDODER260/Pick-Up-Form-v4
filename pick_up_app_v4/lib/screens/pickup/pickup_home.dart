import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/pickup_provider.dart';
import 'package:pickup_delivery_app/screens/pickup/add_po_screen.dart';
import 'package:pickup_delivery_app/screens/company/company_selection_screen.dart';

class PickupHomeScreen extends StatefulWidget {
  @override
  _PickupHomeScreenState createState() => _PickupHomeScreenState();
}

class _PickupHomeScreenState extends State<PickupHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load POs when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PickupProvider>(context, listen: false).loadPOs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final pickupProvider = Provider.of<PickupProvider>(context);

    return Scaffold(
      body: Padding(
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
                      'PICKUP MODE',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      appProvider.selectedRoute.isNotEmpty
                          ? 'Route: ${appProvider.selectedRoute}'
                          : 'No route selected',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (appProvider.selectedCompany.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        'Company: ${appProvider.selectedCompany}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Route selection dialog
                            final routes = Provider.of<AppProvider>(context, listen: false).availableRoutes;
                            final selected = await showDialog<String?>(
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: Text('Select Route'),
                                children: routes.map((r) => SimpleDialogOption(
                                  child: Text(r),
                                  onPressed: () => Navigator.pop(context, r),
                                )).toList(),
                              ),
                            );
                            if (selected != null) {
                              appProvider.selectedRoute = selected;
                              // Clear selected company when route changes
                              appProvider.selectedCompany = '';
                            }
                          },
                          child: Text('Select Route'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Open company selection screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CompanySelectionScreen()),
                            );
                          },
                          child: Text('Select Company'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Action Buttons
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context: context,
                  icon: Icons.add,
                  title: 'Add New PO',
                  onTap: () {
                    Provider.of<PickupProvider>(context, listen: false).setEditingIndex(null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPOScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.cloud_upload,
                  title: 'Upload Selected',
                  onTap: () async {
                    try {
                      await pickupProvider.uploadSelected(appProvider.uploadUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Uploaded selected POs'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.delete,
                  title: 'Delete Selected',
                  onTap: () async {
                    final count = pickupProvider.selectedCount;
                    if (count == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No items selected')));
                      return;
                    }
                    await pickupProvider.deleteSelected();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted selected POs')));
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.select_all,
                  title: 'Select All',
                  onTap: () {
                    pickupProvider.selectAll();
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // PO List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pickup Orders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    pickupProvider.loadPOs();
                  },
                ),
              ],
            ),

            // PO List
            Expanded(
              child: ListView.builder(
                itemCount: pickupProvider.pos.length,
                itemBuilder: (context, index) {
                  final po = pickupProvider.pos[index];
                  final selected = pickupProvider.selectedIndices.contains(index);
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (_) => pickupProvider.toggleSelection(index),
                      ),
                      title: Text(po.description),
                      subtitle: Text('${po.company} • ${po.route} • Qty: ${po.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              pickupProvider.setEditingIndex(index);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddPOScreen()),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await pickupProvider.deletePO(index);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PO deleted')));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}