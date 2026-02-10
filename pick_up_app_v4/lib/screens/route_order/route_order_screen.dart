import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pickup_delivery_app/providers/app_provider.dart';
import 'package:pickup_delivery_app/providers/route_order_provider.dart';
import 'package:pickup_delivery_app/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/route_order_model.dart';

class RouteOrderScreen extends StatefulWidget {
  @override
  _RouteOrderScreenState createState() => _RouteOrderScreenState();
}

class _RouteOrderScreenState extends State<RouteOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final routeProvider = Provider.of<RouteOrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Route Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth >= 600;

            return Column(
              children: [
                // Route Selection and View Mode for tablet layout
                if (isTablet)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Route Selection Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    DropdownButton<String>(
                                      value: appProvider.selectedRoute.isNotEmpty
                                          ? appProvider.selectedRoute
                                          : null,
                                      items: appProvider.availableRoutes
                                          .map((route) {
                                        return DropdownMenuItem(
                                          value: route,
                                          child: Text(route),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        appProvider.selectedRoute = value!;
                                      },
                                      hint: Text('Select Route'),
                                      isExpanded: true,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View Mode:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              routeProvider.setViewMode('single');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              routeProvider.viewMode ==
                                                  'single'
                                                  ? Theme.of(context).primaryColor
                                                  : Colors.grey,
                                            ),
                                            child: Text('Single View'),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              routeProvider.setViewMode('overview');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                              routeProvider.viewMode ==
                                                  'overview'
                                                  ? Theme.of(context)
                                                  .primaryColor
                                                  : Colors.grey,
                                            ),
                                            child: Text('Overview View'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                // Mobile layout (original structure)
                  Column(
                    children: [
                      // Route Selection
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              DropdownButton<String>(
                                value: appProvider.selectedRoute.isNotEmpty
                                    ? appProvider.selectedRoute
                                    : null,
                                items: appProvider.availableRoutes.map((route) {
                                  return DropdownMenuItem(
                                    value: route,
                                    child: Text(route),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  appProvider.selectedRoute = value!;
                                },
                                hint: Text('Select Route'),
                                isExpanded: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // View Mode Toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Mode:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        routeProvider.setViewMode('single');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        routeProvider.viewMode == 'single'
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                      child: Text('Single View'),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        routeProvider.setViewMode('overview');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        routeProvider.viewMode == 'overview'
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                      child: Text('Overview View'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: 20),

                // Load Route Button
                ElevatedButton.icon(
                  onPressed: () {
                    _loadRouteOrder(context);
                  },
                  icon: Icon(Icons.download),
                  label: Text('Load Route Order'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),

                SizedBox(height: 20),

                // Display based on view mode
                Expanded(
                  child: routeProvider.viewMode == 'single'
                      ? _buildSingleView(routeProvider)
                      : _buildOverviewView(routeProvider),
                ),

                SizedBox(height: 20),

                // Navigation for single view
                if (routeProvider.viewMode == 'single' &&
                    routeProvider.stops.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: routeProvider.hasPrevious
                            ? routeProvider.previousStop
                            : null,
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back),
                            SizedBox(width: 4),
                            Text('Previous'),
                          ],
                        ),
                      ),
                      Text(routeProvider.currentStopText),
                      ElevatedButton(
                        onPressed:
                        routeProvider.hasNext ? routeProvider.nextStop : null,
                        child: Row(
                          children: [
                            Text('Next'),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSingleView(RouteOrderProvider provider) {
    final currentStop = provider.currentStop;

    if (provider.stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stops loaded',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Press "Load Route Order" to fetch stops',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (currentStop == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStop.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            _buildDetailRow('Latitude:', currentStop.latCoords),
            _buildDetailRow('Longitude:', currentStop.longCoords),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Coordinates',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    // Copy to clipboard
                    Clipboard.setData(
                      ClipboardData(
                          text: '${currentStop.latCoords}, ${currentStop.longCoords}'),
                    ).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coordinates copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    });
                  },
                ),
              ),
              controller: TextEditingController(
                text: '${currentStop.latCoords}, ${currentStop.longCoords}',
              ),
              readOnly: true,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                // Open in maps
                final url =
                    'https://www.google.com/maps/search/?api=1&query=${currentStop.latCoords},${currentStop.longCoords}';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              icon: Icon(Icons.map),
              label: Text('Open in Maps'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewView(RouteOrderProvider provider) {
    if (provider.stops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No stops loaded',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.stops.length,
      itemBuilder: (context, index) {
        final stop = provider.stops[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(stop.sortNum.isEmpty ? '${index + 1}' : stop.sortNum),
            ),
            title: Text(stop.name),
            subtitle: Text('Lat: ${stop.latCoords}, Lon: ${stop.longCoords}'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              provider.setViewMode('single');
              provider.setStopIndex(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRouteOrder(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final routeProvider = Provider.of<RouteOrderProvider>(context, listen: false);

    if (appProvider.selectedRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a route first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final stops = await ApiService().fetchRouteOrder(
          appProvider.routeOrderUrl, appProvider.selectedRoute);

      if (stops.isNotEmpty) {
        routeProvider.setRouteStops(stops, appProvider.selectedRoute);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${stops.length} stops'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
    } catch (e) {
      print('Error fetching route order: $e');
    }

    // Fallback to dummy data if API fails
    final dummyStops = [
      RouteStop(
        name: 'First Stop',
        latCoords: '41.40338',
        longCoords: '2.17403',
        sortNum: '1',
      ),
      RouteStop(
        name: 'Second Stop',
        latCoords: '41.40542',
        longCoords: '2.17940',
        sortNum: '2',
      ),
      RouteStop(
        name: 'Third Stop',
        latCoords: '41.40756',
        longCoords: '2.18245',
        sortNum: '3',
      ),
    ];

    routeProvider.setRouteStops(dummyStops, appProvider.selectedRoute);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded ${dummyStops.length} stops (offline)'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}