// lib/presentation/widgets/routes_selection_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_event.dart';
import 'package:pttms/blocs/routes_bloc/routes_state.dart';
import 'package:pttms/data/models/route_model.dart';

class RoutesSelectionWidget extends StatelessWidget {
  const RoutesSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row for the location icon + dropdown
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
              child: BlocBuilder<RoutesBloc, RouteState>(
                builder: (context, state) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<RouteModel>(
                      isExpanded: true,
                      hint: const Text('Select Route'),
                      value: null,
                      items: state.availableRoutes.map((route) {
                        return DropdownMenuItem<RouteModel>(
                          value: route,
                          child: Text(route.name),
                        );
                      }).toList(),
                      onChanged: (RouteModel? selectedRoute) {
                        if (selectedRoute != null) {
                          context
                              .read<RoutesBloc>()
                              .add(RouteSelected(selectedRoute));
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

        // Toggle for vehicle type
        BlocBuilder<RoutesBloc, RouteState>(
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

        // Display selected routes
        BlocBuilder<RoutesBloc, RouteState>(
          builder: (context, state) {
            return Column(
              children: state.selectedRoutes.map((route) {
                // Mock data for demonstration
                final waitTime = '> 5 mins';
                final eta = '< 5 mins';
                final trafficLevel = 'Moderate';
                final arrivalTime = '8:32 AM';
                final departureTime = '8:35 AM';
                final lastUpdated = '8:35 AM';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Top row: route name on the left, vehicle icon + close on the right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Route name
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
                                    context
                                        .read<RoutesBloc>()
                                        .add(RouteRemoved(route.name));
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
                        // Divider
                        const Divider(thickness: 1, color: Colors.black54),
                        const SizedBox(height: 8),

                        // Table with 4 columns:
                        // 0: label (Incoming)
                        // 1: data (Incoming)
                        // 2: label (Outgoing)
                        // 3: data (Outgoing)

                        Table(
                          columnWidths: const {
                            0: IntrinsicColumnWidth(),
                            1: FlexColumnWidth(1),
                            2: IntrinsicColumnWidth(),
                            3: FlexColumnWidth(1),
                          },
                          children: [
                            // Row 1: Headings for Incoming, Outgoing
                            TableRow(
                              children: [
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Text(
                                    'Incoming  ',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Empty cell next to "Incoming"
                                const SizedBox(),
                                TableCell(
                                  verticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  child: Text(
                                    'Outgoing  ',
                                    textAlign: TextAlign.left,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Empty cell next to "Outgoing"
                                const SizedBox(),
                              ],
                            ),
                            // Row 2: Wait Time, Arrival Time
                            TableRow(
                              children: [
                                Text(
                                  'Wait Time  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  waitTime,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
                                ),
                                Text(
                                  'Arrival Time  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  arrivalTime,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
                                ),
                              ],
                            ),
                            // Row 3: ETA, Departure Time
                            TableRow(
                              children: [
                                Text(
                                  'ETA  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  eta,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
                                ),
                                Text(
                                  'Departure Time  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  departureTime,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
                                ),
                              ],
                            ),
                            // Row 4: Traffic Level, skip outgoing columns
                            TableRow(
                              children: [
                                Text(
                                  'Traffic Level  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  trafficLevel,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
                                ),
                                Text(
                                  'Last Updated  ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  lastUpdated,
                                  style: const TextStyle(fontSize: 14, color:Colors.blue),
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
