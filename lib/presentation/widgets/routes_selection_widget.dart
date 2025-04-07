import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_event.dart';
import 'package:pttms/blocs/routes_bloc/routes_state.dart';
import 'package:pttms/data/models/route_card_data.dart';
import 'package:pttms/blocs/route_card_bloc/route_card_bloc.dart';

class RoutesSelectionWidget extends StatelessWidget {
  const RoutesSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row: location icon + route dropdown.
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
        // Display cards for each selected route.
        BlocBuilder<RoutesBloc, RoutesState>(
          builder: (context, routesState) {
            return Column(
              children: routesState.selectedRoutes.map((route) {
                return BlocProvider<RouteCardBloc>(
                  create: (context) => RouteCardBloc(
                    routeName: route.name,
                    activeVehicleStreamRepository: context.read(),
                    trafficService: context.read(),
                    ticker: context.read(),
                  )..add(const RouteCardStart()),
                  child: BlocBuilder<RouteCardBloc, RouteCardState>(
                    builder: (context, state) {
                      // Determine if there's data and set card color.
                      bool hasData = false;
                      if (state is RouteCardLoaded) {
                        hasData = state.hasData;
                      }
                      final cardColor = hasData
                          ? const Color(0xFFF9FFF7)
                          : Colors.white;

                      // Determine route status text ("Active" or "Inactive").
                      final routeStatusText = hasData ? "Active" : "Inactive";

                      return Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              // Top row: route name, route status, vehicle icon, remove button.
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        route.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        " ($routeStatusText)",
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                              // Table for route card data.
                              Table(
                                columnWidths: const {
                                  0: IntrinsicColumnWidth(),
                                  1: FlexColumnWidth(1),
                                  2: IntrinsicColumnWidth(),
                                  3: FlexColumnWidth(1),
                                },
                                children: [
                                  // Row 1: Headers.
                                  const TableRow(
                                    children: [
                                      Text(
                                        'Incoming',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(),
                                      Text(
                                        'Outgoing',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(),
                                    ],
                                  ),
                                  // Row 2: Average Wait Time and Arrival Time.
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Avg Wait Time :',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      BlocBuilder<RouteCardBloc, RouteCardState>(
                                        builder: (context, state) {
                                          if (state is RouteCardLoaded) {
                                            if (state.averageWaitTime == null) {
                                              return const Text('-', style: TextStyle(fontSize: 14));
                                            } else {
                                              final avgWaitSec = state.averageWaitTime!;
                                              final avgWaitMin = avgWaitSec < 60
                                                  ? 1
                                                  : (avgWaitSec / 60).round();
                                              return Text('$avgWaitMin min',
                                                  style: const TextStyle(fontSize: 14));
                                            }
                                          } else {
                                            return const Text('-', style: TextStyle(fontSize: 14));
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
                                      BlocBuilder<RouteCardBloc, RouteCardState>(
                                        builder: (context, state) {
                                          if (state is RouteCardLoaded) {
                                            return Text(
                                              state.eta,
                                              style: const TextStyle(fontSize: 14),
                                            );
                                          } else {
                                            return const Text('-', style: TextStyle(fontSize: 14));
                                          }
                                        },
                                      ),
                                      const Text(
                                        'Departure Time :',
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
                                        'Last Updated :',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      BlocBuilder<RouteCardBloc, RouteCardState>(
                                        builder: (context, state) {
                                          if (state is RouteCardLoaded) {
                                            return Text(
                                              state.lastUpdated,
                                              style: const TextStyle(fontSize: 14),
                                            );
                                          } else {
                                            return const Text('N/A', style: TextStyle(fontSize: 14));
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
                    },
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
