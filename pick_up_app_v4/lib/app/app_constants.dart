class AppConstants {
  // App info
  static const String appName = 'Pick Up & Delivery';
  static const String appVersion = '4.0.1.1';
  static const String packageName = 'com.doublersharpening.pickupdelivery';

  // API endpoints
  static const String defaultUploadUrl = "https://doublersharpening.com/api/upload_po/";
  static const String defaultUpdateCheckUrl = "https://doublersharpening.com/media/mypoapp/";
  static const String defaultCompanyDbUrl = "https://doublersharpening.com/api/company_db/";
  static const String defaultDeliveryUrl = "https://doublersharpening.com/api/delivery_pos/";
  static const String defaultRouteOrderUrl = "https://doublersharpening.com/api/route_order/";

  // Storage paths
  static const String poDataFile = 'po_data.json';
  static const String companyDatabaseFile = 'company_database.json';
  static const String deliveryDataFile = 'delivery_data.json';
  static const String routeOrderCacheFile = 'route_order_cache.json';
  static const String appSettingsFile = 'app_settings.json';

  // PDF settings
  static const String pdfFolder = 'PickUpForms';

  // Default routes
  static const List<String> defaultRoutes = [
    "Mercer",
    "Punxy",
    "Middlefield",
    "Sparty",
    "Conneautville",
    "Townville",
    "Holmes County",
    "Cochranton"
  ];

  // Display order for POs
  static const List<String> displayOrder = [
    "uploaded",
    "description",
    "company",
    "route"
  ];
}