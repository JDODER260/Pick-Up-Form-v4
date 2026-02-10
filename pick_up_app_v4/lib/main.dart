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
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:http/http.dart" as http;
import "dart:convert";

// ==========================================
// Local Notifications Plugin
// ==========================================
final FlutterLocalNotificationsPlugin local_notifications =
FlutterLocalNotificationsPlugin();

// ==========================================
// Firebase Background Handler
// ==========================================
@pragma("vm:entry-point")
Future<void> _firebase_background_handler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.notification?.title}");
}


// ==========================================
// Request Notification Permissions
// ==========================================
Future<void> request_notification_permission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

// ==========================================
// Initialize Local Notifications + Channel
// ==========================================
Future<void> init_local_notifications() async {
  const android_settings =
  AndroidInitializationSettings("@mipmap/ic_launcher");

  const init_settings = InitializationSettings(
    android: android_settings,
  );

  await local_notifications.initialize(init_settings);

  const android_channel = AndroidNotificationChannel(
    "default_channel",
    "General Notifications",
    description: "App notifications",
    importance: Importance.max,
  );

  final android_plugin =
  local_notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await android_plugin?.createNotificationChannel(android_channel);
}

// ==========================================
// Foreground FCM Listener (REQUIRED)
// ==========================================
void setup_foreground_fcm_listener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const android_details = AndroidNotificationDetails(
      "default_channel",
      "General Notifications",
      importance: Importance.max,
      priority: Priority.high,
    );

    const notification_details =
    NotificationDetails(android: android_details);

    await local_notifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notification_details,
    );
  });
}

// ==========================================
// Get FCM Device Token
// ==========================================
Future<String?> get_fcm_token() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();
  print("FCM Token: $token");
  return token;
}

// ==========================================
// Send token to Django backend
// ==========================================
Future<void> register_token_with_server(String token, BuildContext context) async {
  final appProvider = Provider.of<AppProvider>(context, listen: false);
  final url = Uri.parse(appProvider.registerFcmUrl);
  await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({"token": token, "driver_id": appProvider.driverId}),
  );
}

// ==========================================
// Main Entry
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebase_background_handler);

  await request_notification_permission();
  await init_local_notifications();
  setup_foreground_fcm_listener();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

// ==========================================
// App Widget
// ==========================================
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
        selector: (context, app_provider) => app_provider.themeMode,
        builder: (context, theme_mode, child) {
          return MaterialApp(
            title: "Pick Up & Delivery",
            debugShowCheckedModeBanner: false,
            themeMode: theme_mode,
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

            return FutureBuilder<bool>(
              future: _initialize_providers(context),
              builder: (context, init_snapshot) {
                if (init_snapshot.connectionState == ConnectionState.waiting) {
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

  // ==========================================
  // Initialize Providers + Register FCM
  // ==========================================
  Future<bool> _initialize_providers(BuildContext context) async {
    try {
      final app_provider =
      Provider.of<AppProvider>(context, listen: false);
      final pickup_provider =
      Provider.of<PickupProvider>(context, listen: false);
      final delivery_provider =
      Provider.of<DeliveryProvider>(context, listen: false);
      final route_provider =
      Provider.of<RouteOrderProvider>(context, listen: false);
      final company_provider =
      Provider.of<CompanyProvider>(context, listen: false);

      await app_provider.initializeApp();
      await pickup_provider.loadPOs();
      await delivery_provider.loadDeliveryData();
      await route_provider.loadRouteOrderCache(
        app_provider.selectedRoute.isNotEmpty
            ? app_provider.selectedRoute
            : null,
      );
      await company_provider.loadCompanyDatabase();

      String? token = await get_fcm_token();
      if (token != null) {
        await register_token_with_server(token, context);
      }

      return true;
    } catch (e) {
      print("Initialization error: $e");
      return false;
    }
  }
}

// ==========================================
// Permission Denied Screen
// ==========================================
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
                "This app needs permissions to function properly.\n\n"
                    "Please grant permissions in app settings.",
                textAlign: TextAlign.center,
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
