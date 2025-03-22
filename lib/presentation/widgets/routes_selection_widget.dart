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
        // Toggle for vehicle type.
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
                print('Vehicle type selected: $newType'); // Debug print
              },
              children: const [
                Icon(Icons.directions_bus, size: 35),
                Icon(Icons.directions_bus_outlined, size: 35),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Dropdown for available routes.
        BlocBuilder<RoutesBloc, RouteState>(
          builder: (context, state) {
            return DropdownButton<RouteModel>(
              hint: const Text('Select a route'),
              value: null, // No single selected value; multiple selections allowed.
              items: state.availableRoutes.map((route) {
                return DropdownMenuItem<RouteModel>(
                  value: route,
                  child: Text(route.name),
                );
              }).toList(),
              onChanged: (RouteModel? selectedRoute) {
                if (selectedRoute != null) {
                  context.read<RoutesBloc>().add(RouteSelected(selectedRoute));
                }
              },
            );
          },
        ),
        const SizedBox(height: 16),
        // Display selected routes.
        BlocBuilder<RoutesBloc, RouteState>(
          builder: (context, state) {
            return Column(
              children: state.selectedRoutes.map((route) {
                return Card(
                  child: ListTile(
                    // Display vehicle type in uppercase along with route name.
                    title: Text('${route.vehicleType.toUpperCase()} - ${route.name}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<RoutesBloc>().add(RouteRemoved(route.name));
                      },
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
