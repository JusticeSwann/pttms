import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc_bloc.dart';

class GoogleMapsWidget extends StatefulWidget {
  final bool showPolyline;  // Added parameter

  const GoogleMapsWidget({
    super.key,
    required this.showPolyline,
  });
  
  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController;
  
  @override
  void initState() {
    super.initState();
    // Dispatch initial event to load the map's current location.
    context.read<MapBloc>().add(MapLoad());
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to MapBloc for camera updates and to trigger route tracking.
        BlocListener<MapBloc, MapState>(
          listener: (context, mapState) {
            if (mapState is MapLoaded && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(mapState.position),
              );
              // Update route tracking with the current position.
              context
                  .read<RouteTrackingBlocBloc>()
                  .add(UpdateRouteTracking(mapState.position));
            }
          },
        ),
        // Optionally, listen to RouteTrackingBloc for errors.
        BlocListener<RouteTrackingBlocBloc, RouteTrackingBlocState>(
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
            return BlocBuilder<RouteTrackingBlocBloc, RouteTrackingBlocState>(
              builder: (context, routeState) {
                // Prepare polyline and status text based on route tracking state.
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
                  // Use widget.showPolyline here
                  if (routeState.isOnRoute && widget.showPolyline) {
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
                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: mapState.position,
                        zoom: 15,
                      ),
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      polylines: polylines,
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
