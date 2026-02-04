import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/screens/drawer_screen.dart';
import 'package:pickup_delivery_app/screens/pickup/pickup_home.dart';
import 'package:pickup_delivery_app/screens/delivery/delivery_home.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appProvider.selectedRoute.isNotEmpty
            ? '${appProvider.selectedRoute} - ${appProvider.appMode.toUpperCase()}'
            : 'Pick Up & Delivery'),
        centerTitle: true,
      ),
      drawer: DrawerScreen(),
      body: _buildBody(appProvider),
    );
  }

  Widget _buildBody(AppProvider appProvider) {
    if (appProvider.appMode == 'pickup') {
      return PickupHomeScreen();
    } else {
      return DeliveryHomeScreen();
    }
  }
}