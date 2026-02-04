import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/company_provider.dart';
import 'package:pickup_delivery_app/screens/company/company_management_screen.dart';

class CompanySelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context);

    final selectedRoute = appProvider.selectedRoute;

    if (selectedRoute.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a route first')),
        );
        Navigator.of(context).pop();
      });
      return SizedBox.shrink();
    }

    final dbCompanies = companyProvider.companyDatabase[selectedRoute]?.companies.keys.toList() ?? [];
    final deliveryCompanies = appProvider.deliveryData?.companies.map((c) => c.companyName).toList() ?? [];

    final allCompaniesSet = <String>{};
    allCompaniesSet.addAll(dbCompanies);
    allCompaniesSet.addAll(deliveryCompanies);

    final companies = allCompaniesSet.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Select Company')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('➕ Add New Company'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CompanyManagementScreen()));
              },
            ),
            SizedBox(height: 12),
            Expanded(
              child: companies.isEmpty
                  ? Center(child: Text('No companies found for this route.'))
                  : ListView.builder(
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        final hasDelivery = deliveryCompanies.contains(company);
                        final display = hasDelivery ? '📦 $company' : company;

                        return Card(
                          child: ListTile(
                            title: Text(display),
                            onTap: () {
                              // Set selected company in global AppProvider
                              appProvider.selectedCompany = company;

                              // If delivery mode and company in delivery list, set current delivery index
                              if (appProvider.appMode == 'delivery' && hasDelivery) {
                                final idx = appProvider.deliveryData?.companies.indexWhere((c) => c.companyName == company) ?? -1;
                                if (idx >= 0) {
                                  appProvider.setDeliveryIndex(idx);
                                } else {
                                  appProvider.setDeliveryIndex(0);
                                }
                              }

                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
