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
          // Use the showPolyline flag from RouteTrackingBloc state, defaulting to true.
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
          ];
          
          // Show the polyline toggle only if the user is on a route.
          if (routeState is RouteTrackingLoaded && routeState.isOnRoute) {
            buttons.add(const SizedBox(height: 10));
            buttons.add(
              FloatingActionButton(
                heroTag: 'togglePolyline',
                onPressed: () {
                  context.read<RouteTrackingBloc>().add(ToggleRoutePolyline());
                },
                child: Icon(
                  routeState.showPolyline ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            );
          }
          
          // Add a new button to trigger a test upload.
          buttons.add(const SizedBox(height: 10));
          buttons.add(
            FloatingActionButton(
              heroTag: 'uploadTestData',
              onPressed: () {
                // Dispatch an upload event with sample test data.
                context.read<MapBloc>().add(
                  UploadVehicleTrackingData(
                    deviceId: "testDevice123",
                    routeId: 1,
                    routeName: "Test Route",
                    activeTime: 100,
                    waitingTime: 50,
                    speed: 40.5,
                    status: "Active",
                    lastLocation: const LatLng(10.0, -61.0),
                    routeTrace: const [
                      LatLng(10.0, -61.0),
                      LatLng(10.1, -61.1)
                    ],
                    stopsMade: const [LatLng(10.05, -61.05)],
                    pickupPoint: const LatLng(10.0, -61.0),
                    userOnRoute: true,
                    gpsAccuracy: 5.0,
                    distanceTraveled: 1200.0,
                    weekendIndicator: false,
                    weatherConditions: "Clear",
                    trafficConditions: "Moderate",
                    startedWaiting: DateTime.now().subtract(const Duration(minutes: 10)),
                    startedTraveling: DateTime.now().subtract(const Duration(minutes: 8)),
                    stoppedTraveling: DateTime.now().subtract(const Duration(minutes: 2)),
                    totalCommuteTime: 10,
                    totalWaitTime: 2,
                    dateTime: DateTime.now(),
                    trafficLevel: "Low",
                    averageTrafficLevel: "Moderate",
                  ),
                );
              },
              child: const Icon(Icons.cloud_upload),
            ),
          );
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: buttons,
          );
        },
      ),
    );
  }
}