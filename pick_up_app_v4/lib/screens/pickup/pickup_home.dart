import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/pickup_provider.dart';
import 'package:pickup_delivery_app/screens/pickup/add_po_screen.dart';
import 'package:pickup_delivery_app/screens/company/company_selection_screen.dart';

import '../../providers/app_provider.dart';
import '../../providers/company_provider.dart';

class PickupHomeScreen extends StatefulWidget {
  const PickupHomeScreen({Key? key}) : super(key: key);

  @override
  _PickupHomeScreenState createState() => _PickupHomeScreenState();
}

class _PickupHomeScreenState extends State<PickupHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final pickupProvider = Provider.of<PickupProvider>(context, listen: false);
    final companyProvider =
        Provider.of<CompanyProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Load company database
    await companyProvider.loadCompanyDatabase();

    // Initialize from saved preferences
    await companyProvider.initializeFromPreferences();

    // Sync with AppProvider
    if (companyProvider.selectedRoute.isNotEmpty) {
      appProvider.selectedRoute = companyProvider.selectedRoute;
    }
    if (companyProvider.selectedCompany.isNotEmpty) {
      appProvider.selectedCompany = companyProvider.selectedCompany;
    }

    // Load pickup orders
    await pickupProvider.loadPOs();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final pickupProvider = Provider.of<PickupProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW (LEFT + RIGHT COLUMNS)
              SizedBox(
                width: double.infinity,
                height: 152,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN (existing content)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "PICKUP MODE",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Selector<AppProvider, String>(
                                selector: (_, provider) =>
                                    provider.selectedRoute,
                                builder: (_, route, __) {
                                  return Text(
                                    route.isNotEmpty
                                        ? "Route: $route"
                                        : "No route selected",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontSize: 12),
                                  );
                                },
                              ),
                              const SizedBox(height: 3),
                              Selector<AppProvider, String>(
                                selector: (_, provider) =>
                                    provider.selectedCompany,
                                builder: (_, company, __) {
                                  return Text(
                                    company.isNotEmpty
                                        ? "Company: $company"
                                        : "No company selected",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontSize: 12),
                                  );
                                },
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 22),
                                    ),
                                    onPressed: () async {
                                      final routes =
                                          companyProvider.availableRoutes;

                                      if (routes.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text("No routes available"),
                                          ),
                                        );
                                        return;
                                      }

                                      final selected =
                                          await showDialog<String?>(
                                        context: context,
                                        builder: (context) => SimpleDialog(
                                          title: const Text("Select Route"),
                                          children: routes
                                              .map(
                                                (r) => SimpleDialogOption(
                                                  child: Text(r),
                                                  onPressed: () {
                                                    Navigator.pop(context, r);
                                                  },
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      );

                                      if (selected != null &&
                                          selected.isNotEmpty) {
                                        companyProvider
                                            .setSelectedRoute(selected);
                                        appProvider.selectedRoute = selected;
                                        appProvider.selectedCompany = "";
                                      }
                                    },
                                    child: const Text("Select Route"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 22),
                                    ),
                                    onPressed: () {
                                      if (appProvider.selectedRoute.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Please select a route first"),
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CompanySelectionScreen(),
                                        ),
                                      ).then((_) {
                                        // Update app provider when returning from selection
                                        appProvider.selectedCompany =
                                            companyProvider.selectedCompany;
                                      });
                                    },
                                    child: const Text("Select Company"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // RIGHT COLUMN (Navigation buttons)
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // NAVIGATION BUTTONS ROW
                              Row(
                                children: [
                                  // Previous Button
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (companyProvider
                                            .selectedRoute.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Please select a route first"),
                                            ),
                                          );
                                          return;
                                        }

                                        await companyProvider
                                            .selectPreviousCompany();
                                        appProvider.selectedCompany =
                                            companyProvider.selectedCompany;
                                      },
                                      child: const Icon(Icons.arrow_back,
                                          size: 16),
                                    ),
                                  ),

                                  // Next Button
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (companyProvider
                                            .selectedRoute.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Please select a route first"),
                                            ),
                                          );
                                          return;
                                        }

                                        await companyProvider
                                            .selectNextCompany();
                                        appProvider.selectedCompany =
                                            companyProvider.selectedCompany;
                                      },
                                      child: const Icon(Icons.arrow_forward,
                                          size: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // SMALL LABEL AND SYNC INFO
                              Column(
                                children: [
                                  Selector<CompanyProvider, String>(
                                    selector: (_, provider) =>
                                        provider.getSelectedCompanyLabel(),
                                    builder: (_, label, __) {
                                      return Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  Selector<CompanyProvider, String>(
                                    selector: (_, provider) =>
                                        provider.lastSyncText,
                                    builder: (_, syncText, __) {
                                      return Text(
                                        syncText,
                                        style: const TextStyle(
                                          fontSize: 7,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ACTION BUTTONS
            SizedBox(
              height: 110, // ← SET HEIGHT ONLY (adjust this)
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildResponsiveActionCard(
                      icon: Icons.add,
                      title: "Add New PO",
                      color: Colors.blue,
                      onTap: () {
                        if (appProvider.selectedRoute.isEmpty ||
                            appProvider.selectedCompany.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select route and company first"),
                            ),
                          );
                          return;
                        }

                        Provider.of<PickupProvider>(context, listen: false)
                            .setEditingIndex(null);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddPOScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponsiveActionCard(
                      icon: Icons.cloud_upload,
                      title: "Upload Selected",
                      color: Colors.green,
                      onTap: () async {
                        if (pickupProvider.selectedCount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No POs selected for upload"),
                            ),
                          );
                          return;
                        }

                        try {
                          await pickupProvider.uploadSelected(appProvider.uploadUrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selected POs uploaded successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          final msg = e
                              .toString()
                              .replaceFirst(RegExp(r'^Exception:\s*'), '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Upload failed: $msg"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponsiveActionCard(
                      icon: Icons.delete,
                      title: "Delete Selected",
                      color: Colors.red,
                      onTap: () async {
                        if (pickupProvider.selectedCount == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No items selected")),
                          );
                          return;
                        }

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: Text(
                              "Delete ${pickupProvider.selectedCount} selected POs?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await pickupProvider.deleteSelected();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Deleted ${pickupProvider.selectedCount} POs",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildResponsiveActionCard(
                      icon: Icons.select_all,
                      title: "Select All",
                      color: Colors.orange,
                      onTap: pickupProvider.selectAll,
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 8),

              // HEADER with stats
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pickup Orders",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Selector<PickupProvider, int>(
                            selector: (_, provider) => provider.pos.length,
                            builder: (_, count, __) {
                              final uploaded = pickupProvider.pos
                                  .where((po) => po.uploaded)
                                  .length;
                              return Text(
                                "$count total, $uploaded uploaded",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: "Refresh list",
                            onPressed: () async {
                              await pickupProvider.loadPOs();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("PO list refreshed"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          Selector<PickupProvider, int>(
                            selector: (_, provider) => provider.selectedCount,
                            builder: (_, selectedCount, __) {
                              return Chip(
                                label: Text("$selectedCount selected"),
                                backgroundColor: selectedCount > 0
                                    ? Colors.blue.withOpacity(0.2)
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // LIST
              Flexible(
                child: pickupProvider.pos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No pickup orders yet",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (appProvider.selectedRoute.isEmpty ||
                                    appProvider.selectedCompany.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Please select route and company first"),
                                    ),
                                  );
                                  return;
                                }

                                Provider.of<PickupProvider>(
                                  context,
                                  listen: false,
                                ).setEditingIndex(null);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddPOScreen(),
                                  ),
                                );
                              },
                              child: const Text("Create First PO"),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await pickupProvider.loadPOs();
                        },
                        child: ListView.builder(
                          itemCount: pickupProvider.pos.length,
                          itemBuilder: (context, index) {
                            final po = pickupProvider.pos[index];
                            final selected =
                                pickupProvider.selectedIndices.contains(index);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: selected
                                  ? Colors.blue.withOpacity(0.1)
                                  : null,
                              child: ListTile(
                                leading: Checkbox(
                                  value: selected,
                                  onChanged: (_) =>
                                      pickupProvider.toggleSelection(index),
                                ),
                                title: Text(
                                  po.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    decoration: po.uploaded
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${po.company} • ${po.route} • Qty: ${po.quantity}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: po.uploaded
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.orange
                                                    .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            po.uploaded
                                                ? "UPLOADED"
                                                : "PENDING",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: po.uploaded
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          po.createdAt
                                              .toLocal()
                                              .toString()
                                              .substring(0, 16),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: "Edit PO",
                                      onPressed: () {
                                        pickupProvider.setEditingIndex(index);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddPOScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      tooltip: "Delete PO",
                                      onPressed: () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Delete PO?"),
                                            content: const Text(
                                                "Are you sure you want to delete this pickup order?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          await pickupProvider.deletePO(index);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text("PO deleted"),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double iconSize = constraints.maxHeight * 0.4;
              double fontSize = constraints.maxHeight * 0.15;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: iconSize, color: color),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: fontSize,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
