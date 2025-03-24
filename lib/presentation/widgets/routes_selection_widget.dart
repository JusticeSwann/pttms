import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_event.dart';
import 'package:pttms/blocs/routes_bloc/routes_state.dart';
import 'package:pttms/data/models/route_card_data.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';

class RoutesSelectionWidget extends StatelessWidget {
  const RoutesSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row: location icon + dropdown.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: BlocBuilder<RoutesBloc, RoutesState>(
                builder: (context, state) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<RouteCardData>(
                      isExpanded: true,
                      hint: const Text('Select Route'),
                      value: null,
                      items: state.availableRoutes.map((route) {
                        return DropdownMenuItem<RouteCardData>(
                          value: route,
                          child: Text(route.name),
                        );
                      }).toList(),
                      onChanged: (RouteCardData? selectedRoute) {
                        if (selectedRoute != null) {
                          context.read<RoutesBloc>().add(RouteSelected(selectedRoute));
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Toggle for vehicle type.
        BlocBuilder<RoutesBloc, RoutesState>(
          builder: (context, state) {
            return ToggleButtons(
              isSelected: [
                state.activeVehicleType == 'bus',
                state.activeVehicleType == 'maxi',
              ],
              onPressed: (index) {
                final newType = index == 0 ? 'bus' : 'maxi';
                context.read<RoutesBloc>().add(VehicleTypeSelected(newType));
              },
              borderRadius: BorderRadius.circular(30),
              selectedColor: Colors.white,
              color: Colors.white,
              fillColor: Colors.red,
              children: const [
                Icon(Icons.directions_bus, size: 35),
                Icon(Icons.directions_bus_outlined, size: 35),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Display selected routes.
        BlocBuilder<RoutesBloc, RoutesState>(
          builder: (context, state) {
            return Column(
              children: state.selectedRoutes.map((route) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Top row: route name, vehicle icon, close button.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              route.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  route.vehicleType == 'bus'
                                      ? Icons.directions_bus
                                      : Icons.directions_bus_outlined,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    context.read<RoutesBloc>().add(RouteRemoved(route.name));
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(thickness: 1, color: Colors.black54),
                        const SizedBox(height: 8),

                        // Table: 4 rows for Incoming & Outgoing data.
                        Table(
                          columnWidths: const {
                            0: IntrinsicColumnWidth(),
                            1: FlexColumnWidth(1),
                            2: IntrinsicColumnWidth(),
                            3: FlexColumnWidth(1),
                          },
                          children: [
                            // Row 1: Headings.
                            TableRow(
                              children: [
                                Text(
                                  'Incoming',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(),
                                Text(
                                  'Outgoing',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            // Row 2: Wait Time and Arrival Time.
                            TableRow(
                              children: [
                                const Text(
                                  'Wait Time :',
                                  style: TextStyle(fontSize: 14),
                                ),
                                // Here we replace route.waitTimeDisplay with average wait from MapBloc
                                BlocBuilder<MapBloc, MapState>(
                                  builder: (context, mapState) {
                                    if (mapState is MapLoaded) {
                                      // Convert averageWaitTime from seconds to minutes
                                      final avgWaitSec = mapState.averageWaitTime;
                                      final avgWaitMin = avgWaitSec < 60
                                          ? 1
                                          : (avgWaitSec / 60).round();
                                      return Text(
                                        '$avgWaitMin min',
                                        style: const TextStyle(fontSize: 14),
                                      );
                                    } else {
                                      return const Text(
                                        'N/A',
                                        style: TextStyle(fontSize: 14),
                                      );
                                    }
                                  },
                                ),
                                const Text(
                                  'Arrival Time :',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  '8:32 AM',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            // Row 3: ETA and Departure Time.
                            TableRow(
                              children: [
                                const Text(
                                  'ETA :',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  '< 5 mins',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  'Departure Time :  ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  '8:35 AM',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            // Row 4: Traffic Level and Last Updated.
                            TableRow(
                              children: [
                                const Text(
                                  'Traffic Level :',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  'Moderate',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  'Last Updated :  ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                // Now we display lastUpdated from MapBloc
                                BlocBuilder<MapBloc, MapState>(
                                  builder: (context, mapState) {
                                    if (mapState is MapLoaded) {
                                      return Text(
                                        mapState.lastUpdated,
                                        style: const TextStyle(fontSize: 14),
                                      );
                                    } else {
                                      return const Text(
                                        'N/A',
                                        style: TextStyle(fontSize: 14),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
