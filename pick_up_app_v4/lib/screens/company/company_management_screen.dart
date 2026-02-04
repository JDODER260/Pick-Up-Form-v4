import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:pickup_delivery_app/providers/company_provider.dart";
import "package:pickup_delivery_app/providers/app_provider.dart";

class CompanyManagementScreen extends StatefulWidget {
  @override
  _CompanyManagementScreenState createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final _new_route_controller = TextEditingController();
  final _new_company_controller = TextEditingController();
  final _new_blade_controller = TextEditingController();

  String? _selected_route;
  String? _selected_company;
  String? _editing_blade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CompanyProvider>(context, listen: false)
          .loadCompanyDatabase();
    });
  }

  @override
  void dispose() {
    _new_route_controller.dispose();
    _new_company_controller.dispose();
    _new_blade_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company_provider = Provider.of<CompanyProvider>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final List<String> available_routes =
        company_provider.availableRoutes;

    final List<String> companies_for_route =
    _selected_route == null
        ? []
        : (company_provider.companyDatabase[_selected_route!]?.companies.keys.toList() ?? []);

    final List<String> blades_for_company =
    _selected_route != null && _selected_company != null
        ? company_provider.getFrequentBlades(
      _selected_route!,
      _selected_company!,
    )
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Company Management"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ROUTE SELECTION
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: DropdownButton<String>(
                  value: available_routes.contains(_selected_route)
                      ? _selected_route
                      : null,
                  hint: Text("Select Route"),
                  isExpanded: true,
                  items: available_routes
                      .map(
                        (route) => DropdownMenuItem(
                      value: route,
                      child: Text(route),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selected_route = value;
                      _selected_company = null;
                      _editing_blade = null;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 16),

            /// COMPANY SELECTION
            if (_selected_route != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: DropdownButton<String>(
                    value: companies_for_route.contains(_selected_company)
                        ? _selected_company
                        : null,
                    hint: Text("Select Company"),
                    isExpanded: true,
                    items: companies_for_route
                        .map(
                          (company) => DropdownMenuItem(
                        value: company,
                        child: Text(company),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selected_company = value;
                        _editing_blade = null;
                      });
                    },
                  ),
                ),
              ),

            SizedBox(height: 8),
            if (_selected_route != null && _selected_company != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Set current app route/company
                        appProvider.selectedRoute = _selected_route!;
                        appProvider.selectedCompany = _selected_company!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected route and company set')),
                        );
                      },
                      child: Text('Set as Current'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        // Delete company
                        final route = _selected_route!;
                        final company = _selected_company!;
                        company_provider.deleteCompany(route, company);
                        // Refresh app provider database
                        appProvider.loadCompanyDatabase();
                        setState(() {
                          _selected_company = null;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Company deleted')),
                        );
                      },
                      child: Text('Delete Company'),
                    ),
                  ),
                ],
              ),

            SizedBox(height: 16),

            /// FREQUENT BLADES
            if (_selected_company != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Frequent Blades",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _new_blade_controller,
                        decoration: InputDecoration(
                          labelText: _editing_blade != null
                              ? "Edit Blade"
                              : "New Blade",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final blade =
                          _new_blade_controller.text.trim();
                          if (blade.isEmpty) return;

                          if (_editing_blade != null) {
                            company_provider.deleteFrequentBlade(
                              _selected_route!,
                              _selected_company!,
                              _editing_blade!,
                            );
                          }

                          company_provider.addFrequentBlade(
                            _selected_route!,
                            _selected_company!,
                            blade,
                          );

                          setState(() {
                            _editing_blade = null;
                            _new_blade_controller.clear();
                          });
                        },
                        child: Text(
                          _editing_blade != null
                              ? "Update Blade"
                              : "Add Blade",
                        ),
                      ),
                      SizedBox(height: 16),
                      ...blades_for_company.map(
                            (blade) => ListTile(
                          title: Text(blade),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    _editing_blade = blade;
                                    _new_blade_controller.text = blade;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  company_provider.deleteFrequentBlade(
                                    _selected_route!,
                                    _selected_company!,
                                    blade,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
