import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc.dart';

class GoogleMapsWidget extends StatelessWidget {
  final Completer<GoogleMapController> _controller = Completer();

  GoogleMapsWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MapBloc, MapState>(
          listener: (context, mapState) async {
            if (mapState is MapLoaded) {
              final controller = await _controller.future;
              controller.animateCamera(
                CameraUpdate.newLatLng(mapState.position),
              );
              // Update the route tracking state based on the new position.
              context.read<RouteTrackingBloc>().add(UpdateRouteTracking(mapState.position));
            }
          },
        ),
        BlocListener<RouteTrackingBloc, RouteTrackingState>(
          listener: (context, routeState) {
            if (routeState is RouteTrackingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(routeState.message)),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, mapState) {
          if (mapState is MapLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (mapState is MapLoaded) {
            return BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
              builder: (context, routeState) {
                Set<Polyline> polylines = {};
                String routeStatusText = 'No route data available';
                if (routeState is RouteTrackingLoaded) {
                  if (routeState.routeName == null) {
                    routeStatusText = 'No nearby route detected';
                  } else if (routeState.isOnRoute) {
                    routeStatusText = 'On Route: ${routeState.routeName}';
                  } else {
                    routeStatusText = 'Off Route: ${routeState.routeName}';
                  }
                  if (routeState.showPolyline) {
                    polylines = {
                      Polyline(
                        polylineId: const PolylineId('detectedRoute'),
                        points: routeState.routePolyline,
                        color: Colors.blue,
                        width: 4,
                      ),
                    };
                  }
                }
                // Create markers from active vehicle locations.
                final markers = mapState.activeVehicleLocations.map((vehicleData) {
                  return Marker(
                    markerId: MarkerId(vehicleData.lastLocation.toString()),
                    position: vehicleData.lastLocation,
                    infoWindow: InfoWindow(
                      title: 'Wait: ${vehicleData.waitTime} sec',
                    ),
                  );
                }).toSet();

                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: mapState.position,
                        zoom: 15,
                      ),
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      polylines: polylines,
                      markers: markers,
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          routeStatusText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          } else if (mapState is MapError) {
            return Center(child: Text('Error: ${mapState.message}'));
          }
          return const Center(child: Text('Application Error'));
        },
      ),
    );
  }
}
