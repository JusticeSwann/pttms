import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../blocs/routes_bloc/routes_bloc.dart';
import '../../../blocs/routes_bloc/routes_event.dart';
import '../../../blocs/routes_bloc/routes_state.dart';
import '../../../repositories/routes_repository.dart';
import '../../../data/data_provider.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  String? selectedRoute;
  List<String> availableRoutes = [];
  List<String> selectedRoutes = [];
  List<Map<String, dynamic>> availableRoutesData = []; // Store route data

  @override
  void initState() {
    super.initState();
    _loadSelectedRoutes();
  }

  // Load selected routes from SharedPreferences
  Future<void> _loadSelectedRoutes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedSelectedRoutes = prefs.getStringList('selectedRoutes');
    if (savedSelectedRoutes != null) {
      setState(() {
        selectedRoutes = savedSelectedRoutes;
      });
    }
  }

  Future<void> _saveSelectedRoutes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cache selected routes
    await prefs.setStringList('selectedRoutes', selectedRoutes);

    // Cache pickup points for selected routes
    final selectedPickupPoints = selectedRoutes.expand((routeName) {
      final route = availableRoutesData.firstWhere(
        (r) => r['name'] == routeName,
        orElse: () => {},
      );

      if (route.isEmpty || route['pickup_points'] == null) {
        return [];
      }

      return route['pickup_points'];
    }).toList();

    // Save pickup points to SharedPreferences
    final pickupPointsToSave = selectedPickupPoints.map((point) => '${point[0]},${point[1]}').toList();
    await prefs.setStringList('pickupPoints', pickupPointsToSave);

    // Cache stops for selected routes
    final selectedStops = selectedRoutes.expand((routeName) {
      final route = availableRoutesData.firstWhere(
        (r) => r['name'] == routeName,
        orElse: () => {},
      );

      if (route.isEmpty || route['stops'] == null) {
        return [];
      }

      return route['stops'];
    }).toList();

    // Save stops to SharedPreferences
    final stopsToSave = selectedStops.map((stop) => '${stop[0]},${stop[1]}').toList();
    await prefs.setStringList('routeStops', stopsToSave);

    // Debug: Retrieve and print cached data
    final savedPickupPoints = prefs.getStringList('pickupPoints') ?? [];
    final savedStops = prefs.getStringList('routeStops') ?? [];
    print('Saved Pickup Points in SharedPreferences: $savedPickupPoints');
    print('Saved Route Stops in SharedPreferences: $savedStops');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes Selection'),
      ),
      body: BlocProvider(
        create: (context) => RoutesBloc(RoutesRepository(RoutesDataProvider()))..add(LoadRouteEvent()),
        child: BlocBuilder<RoutesBloc, RoutesState>(
          builder: (context, state) {
            if (state is RoutesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RoutesLoaded) {
              if (availableRoutes.isEmpty) {
                availableRoutes = state.routeNames
                    .where((route) => !selectedRoutes.contains(route))
                    .toList();
                availableRoutesData = state.routes; // Store full route data
                print('Loaded routes with data: $availableRoutesData'); // Debug log
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        hint: const Text('Select a route'),
                        value: selectedRoute,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: availableRoutes.map((route) {
                          return DropdownMenuItem<String>(
                            value: route,
                            child: Text(route),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRoute = value;
                            if (value != null) {
                              selectedRoutes.add(value);
                              availableRoutes.remove(value);
                              _saveSelectedRoutes(); // Save to preferences
                            }
                            selectedRoute = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedRoutes.length,
                        itemBuilder: (context, index) {
                          final route = selectedRoutes[index];
                          return Card(
                            child: ListTile(
                              title: Text(route),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    selectedRoutes.remove(route);
                                    availableRoutes.add(route);
                                    _saveSelectedRoutes(); // Update preferences
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is RoutesError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            return Container();
          },
        ),
      ),
    );
  }
}
