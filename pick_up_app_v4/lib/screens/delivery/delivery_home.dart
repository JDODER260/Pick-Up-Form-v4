import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/delivery_provider.dart';
import 'package:pickup_delivery_app/screens/delivery/delivery_details_screen.dart';
import 'package:pickup_delivery_app/screens/route_order/route_order_screen.dart';
import 'package:pickup_delivery_app/widgets/loading_overlay.dart';
import 'package:pickup_delivery_app/services/api_service.dart';
import 'package:pickup_delivery_app/services/pdf_service.dart';
import '../../services/storage_service.dart';

class DeliveryHomeScreen extends StatefulWidget {
  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
  }

  Future<void> _loadDeliveryData() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    await deliveryProvider.loadDeliveryData();
  }

  Future<void> _downloadRoute() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

    if (appProvider.selectedRoute.isEmpty) {
      _showError('Please select a route first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // API call to fetch delivery data from your server
      final data = await ApiService().fetchDeliveryData(
          appProvider.deliveryUrl,
          appProvider.selectedRoute
      );

      // Check if we got valid data
      if (data == null || data.companies.isEmpty) {
        throw Exception('No delivery data found for route: ${appProvider.selectedRoute}');
      }

      deliveryProvider.setDeliveryData(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${data.companies.length} deliveries'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error downloading delivery data: $e');

      // Show error to user instead of using dummy data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download delivery data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Optional: Check for cached data from previous downloads
      final cachedData = await StorageService().loadDeliveryData();
      if (cachedData != null && cachedData.companies.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using previously downloaded data (${cachedData.companies.length} deliveries)'),
            backgroundColor: Colors.orange,
          ),
        );
        deliveryProvider.setDeliveryData(cachedData);
      } else {
        // If no cached data, you could fetch from a backup endpoint
        // or let the user try again
        _showError('No delivery data available. Please check your connection and try again.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectRoute() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Select Route'),
        children: appProvider.availableRoutes.map((route) => SimpleDialogOption(
          child: Text(route),
          onPressed: () => Navigator.pop(context, route),
        )).toList(),
      ),
    );

    if (selected != null) {
      appProvider.selectedRoute = selected;
    }
  }

  Future<void> _printReceipt() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

    if (deliveryProvider.currentCompany == null) {
      _showError('No company selected to print');
      return;
    }

    final company = deliveryProvider.currentCompany!;

    try {
      final pdfPath = await PdfService().generateDeliveryReceipt(
        companyName: company.companyName,
        poItems: company.poList,
        route: appProvider.selectedRoute,
        driverId: appProvider.driverId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt saved to $pdfPath'), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showError('Failed to generate receipt: $e');
    }
  }

  // Check if device is tablet
  bool get _isTablet {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.shortestSide >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final deliveryProvider = Provider.of<DeliveryProvider>(context);

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isTablet ? 24.0 : 16.0,
                vertical: _isTablet ? 20.0 : 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - More compact
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(_isTablet ? 20.0 : 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERY MODE',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: _isTablet ? 22 : 18,
                            ),
                          ),
                          SizedBox(height: _isTablet ? 12 : 6),
                          Text(
                            appProvider.selectedRoute.isNotEmpty
                                ? 'Route: ${appProvider.selectedRoute}'
                                : 'No route selected',
                            style: TextStyle(
                              fontSize: _isTablet ? 16 : 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Deliveries: ${deliveryProvider.totalDeliveries}',
                            style: TextStyle(
                              fontSize: _isTablet ? 16 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: _isTablet ? 20 : 12),

                  // Action Buttons - Single Row with proper height
                  Container(
                    height: _isTablet ? 100 : 80, // Increased height to prevent overflow
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRowActionButton(
                            icon: Icons.download,
                            label: 'Download',
                            subLabel: 'Route',
                            onTap: _downloadRoute,
                          ),
                        ),
                        SizedBox(width: _isTablet ? 12 : 8),
                        Expanded(
                          child: _buildRowActionButton(
                            icon: Icons.route,
                            label: 'Select',
                            subLabel: 'Route',
                            onTap: _selectRoute,
                          ),
                        ),
                        SizedBox(width: _isTablet ? 12 : 8),
                        Expanded(
                          child: _buildRowActionButton(
                            icon: Icons.list,
                            label: 'Route',
                            subLabel: 'Order',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteOrderScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: _isTablet ? 12 : 8),
                        Expanded(
                          child: _buildRowActionButton(
                            icon: Icons.print,
                            label: 'Print',
                            subLabel: 'Receipt',
                            onTap: _printReceipt,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: _isTablet ? 20 : 12),

                  // Delivery Navigation - Compact
                  if (deliveryProvider.totalDeliveries > 0)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(_isTablet ? 16 : 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, size: _isTablet ? 32 : 28),
                              onPressed: deliveryProvider.previousDelivery,
                              padding: EdgeInsets.all(_isTablet ? 12 : 8),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Delivery ${deliveryProvider.currentIndex + 1} of ${deliveryProvider.totalDeliveries}',
                                    style: TextStyle(
                                      fontSize: _isTablet ? 18 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (deliveryProvider.currentCompany != null)
                                    Text(
                                      deliveryProvider.currentCompany!.companyName,
                                      style: TextStyle(
                                        fontSize: _isTablet ? 16 : 14,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward, size: _isTablet ? 32 : 28),
                              onPressed: deliveryProvider.nextDelivery,
                              padding: EdgeInsets.all(_isTablet ? 12 : 8),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: _isTablet ? 16 : 8),

                  // Delivery Details - Takes more space now
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DeliveryDetailsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_isLoading) LoadingOverlay(message: 'Downloading route...'),
      ],
    );
  }

  Widget _buildRowActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: _isTablet ? 12 : 8,
            horizontal: 4,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: _isTablet ? 28 : 22,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isTablet ? 13 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isTablet ? 12 : 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}