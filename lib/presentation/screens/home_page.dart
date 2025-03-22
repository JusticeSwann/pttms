// lib/presentation/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc.dart';
import 'package:pttms/presentation/widgets/google_maps_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
        builder: (context, routeState) {
          // Use the showPolyline flag from RouteTrackingBloc state.
          bool showPolyline = true;
          if (routeState is RouteTrackingLoaded) {
            showPolyline = routeState.showPolyline;
          }
          return GoogleMapsWidget(showPolyline: showPolyline);
        },
      ),
      floatingActionButton: BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
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
            const SizedBox(height: 10),
            // Test upload button.
            FloatingActionButton(
              heroTag: 'uploadTestData',
              onPressed: () {
                // Implement your test upload functionality here.
              },
              child: const Icon(Icons.airplay_outlined),
            ),
          ];
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: buttons,
          );
        },
      ),
    );
  }
}
