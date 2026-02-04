import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/screens/pickup/pickup_home.dart';
import 'package:pickup_delivery_app/screens/delivery/delivery_home.dart';
import 'package:pickup_delivery_app/screens/route_order/route_order_screen.dart';
import 'package:pickup_delivery_app/screens/company/company_management_screen.dart';
import 'package:pickup_delivery_app/screens/settings/settings_screen.dart';

class DrawerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentMode = appProvider.appMode;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Pick Up & Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'v${appProvider.currentVersion}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Mode Toggle
                ListTile(
                  leading: Icon(currentMode == 'pickup'
                      ? Icons.inventory_2
                      : Icons.delivery_dining),
                  title: Text(
                    currentMode == 'pickup'
                        ? 'Switch to Delivery Mode'
                        : 'Switch to Pickup Mode',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (currentMode == 'pickup') {
                      appProvider.switchToDeliveryMode();
                    } else {
                      appProvider.switchToPickupMode();
                    }
                  },
                ),
                Divider(),

                // Pickup Mode Items
                _buildDrawerItem(
                  context: context,
                  icon: Icons.inventory_2,
                  title: 'Pickup Home',
                  enabled: true,
                  onTap: () {
                    Navigator.pop(context);
                    appProvider.navigateToPickupHome();
                  },
                ),

                // Delivery Mode Items
                _buildDrawerItem(
                  context: context,
                  icon: Icons.delivery_dining,
                  title: 'Delivery Home',
                  enabled: true,
                  onTap: () {
                    Navigator.pop(context);
                    appProvider.navigateToDeliveryHome();
                  },
                ),

                // Shared Items
                _buildDrawerItem(
                  context: context,
                  icon: Icons.route,
                  title: 'Route Order',
                  enabled: appProvider.selectedRoute.isNotEmpty,
                  onTap: () {
                    Navigator.pop(context);
                    if (appProvider.selectedRoute.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteOrderScreen(),
                        ),
                      );
                    }
                  },
                ),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.business,
                  title: 'Company Management',
                  enabled: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyManagementScreen(),
                      ),
                    );
                  },
                ),

                Divider(),

                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Settings',
                  enabled: true,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: enabled
              ? Theme.of(context).iconTheme.color
              : Theme.of(context).disabledColor),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Theme.of(context).disabledColor,
        ),
      ),
      enabled: enabled,
      onTap: onTap,
    );
  }
}