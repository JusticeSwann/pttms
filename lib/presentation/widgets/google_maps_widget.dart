import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';

class GoogleMapsWidget extends StatefulWidget {
  final bool showPolyline;
  const GoogleMapsWidget({super.key, required this.showPolyline});
  
  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController;
  
  @override
  void initState() {
    super.initState();
    // Dispatch initial event to load the map state.
    context.read<MapBloc>().add(MapLoad());
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  /// Returns an appropriate status message based on the current state.
  String _getRouteStatusText(MapLoadedWithRoute state) {
    if (state.routeName == null) {
      return 'No nearby route detected';
    } else if (state.isOnRoute) {
      return 'On Route: ${state.routeName}';
    } else {
      return 'Off Route: ${state.routeName}';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listener: (context, state) {
        if (state is MapLoadedWithRoute && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.position),
          );
        }
      },
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MapLoadedWithRoute) {
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: state.position,
                    zoom: 15,
                  ),
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  // Only show the polyline if both the user is on/near a route AND the toggle is active.
                  polylines: (state.isOnRoute && widget.showPolyline)
                      ? {
                          Polyline(
                            polylineId: const PolylineId('detectedRoute'),
                            points: state.routePolyline,
                            color: Colors.blue,
                            width: 4,
                          ),
                        }
                      : {},
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
                      _getRouteStatusText(state),
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
          } else if (state is MapError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Application Error'));
        },
      ),
    );
  }
}
