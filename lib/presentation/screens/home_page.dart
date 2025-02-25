import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc_bloc.dart';
import 'package:pttms/presentation/widgets/google_maps_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<RouteTrackingBlocBloc, RouteTrackingBlocState>(
        builder: (context, routeState) {
          // Use the showPolyline from route tracking state, defaulting to true.
          bool showPolyline = true;
          if (routeState is RouteTrackingLoaded) {
            showPolyline = routeState.showPolyline;
          }
          return GoogleMapsWidget(showPolyline: showPolyline);
        },
      ),
      floatingActionButton: BlocBuilder<RouteTrackingBlocBloc, RouteTrackingBlocState>(
        builder: (context, routeState) {
          List<Widget> buttons = [
            // Button to update current location using MapBloc.
            FloatingActionButton(
              heroTag: 'currentLocation',
              onPressed: () {
                context.read<MapBloc>().add(MoveToCurrentLocation());
              },
              child: const Icon(Icons.my_location),
            ),
          ];
          
          // Show the polyline toggle only if the user is on a route.
          if (routeState is RouteTrackingLoaded && routeState.isOnRoute) {
            buttons.add(const SizedBox(height: 10));
            buttons.add(
              FloatingActionButton(
                heroTag: 'togglePolyline',
                onPressed: () {
                  context.read<RouteTrackingBlocBloc>().add(ToggleRoutePolyline());
                },
                child: Icon(
                  routeState.showPolyline ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            );
          }
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: buttons,
          );
        },
      ),
    );
  }
}
