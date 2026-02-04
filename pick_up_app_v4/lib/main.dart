import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:pickup_delivery_app/app/app_theme.dart";
import "package:pickup_delivery_app/providers/app_provider.dart";
import "package:pickup_delivery_app/providers/pickup_provider.dart";
import "package:pickup_delivery_app/providers/delivery_provider.dart";
import "package:pickup_delivery_app/providers/route_order_provider.dart";
import "package:pickup_delivery_app/providers/company_provider.dart";
import "package:pickup_delivery_app/screens/home_screen.dart";
import "package:pickup_delivery_app/screens/splash_screen.dart";
import "package:pickup_delivery_app/utils/permission_utils.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => PickupProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => RouteOrderProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
      ],
      child: Selector<AppProvider, ThemeMode>(
        selector: (context, appProvider) => appProvider.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            title: "Pick Up & Delivery",
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            home: child!,
          );
        },
        child: FutureBuilder<bool>(
          future: PermissionUtils.request_all_permissions(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen();
            }

            if (!snapshot.hasData || snapshot.data == false) {
              return PermissionDeniedScreen();
            }

            // Permissions granted - initialize providers and load persisted data
            return FutureBuilder<bool>(
              future: _initializeProviders(context),
              builder: (context, initSnapshot) {
                if (initSnapshot.connectionState == ConnectionState.waiting) {
                  return SplashScreen();
                }

                return HomeScreen();
              },
            );
          },
        ),
      ),
    );
  }

  // Initialize providers to load saved JSON data and settings
  Future<bool> _initializeProviders(BuildContext context) async {
    try {
      final appProv = Provider.of<AppProvider>(context, listen: false);
      final pickupProv = Provider.of<PickupProvider>(context, listen: false);
      final deliveryProv = Provider.of<DeliveryProvider>(context, listen: false);
      final routeProv = Provider.of<RouteOrderProvider>(context, listen: false);
      final companyProv = Provider.of<CompanyProvider>(context, listen: false);

      // AppProvider loads settings, company DB, delivery, route cache
      await appProv.initializeApp();

      // Other providers load their persisted data
      await pickupProv.loadPOs();
      await deliveryProv.loadDeliveryData();
      await routeProv.loadRouteOrderCache(appProv.selectedRoute.isNotEmpty ? appProv.selectedRoute : null);
      await companyProv.loadCompanyDatabase();

      return true;
    } catch (e) {
      print('Provider initialization error: $e');
      return false;
    }
  }
}

class PermissionDeniedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Permissions Required",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                "This app needs the following permissions to function properly:\n\n"
                    "• Storage Access\n"
                    "• Install Packages\n\n"
                    "Please grant permissions in app settings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => PermissionUtils.open_app_settings(),
                child: Text("Open App Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
