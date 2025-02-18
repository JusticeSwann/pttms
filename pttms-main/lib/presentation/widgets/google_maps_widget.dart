import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';

class GoogleMapsWidget extends StatefulWidget {
  const GoogleMapsWidget({super.key});

  @override
  State<GoogleMapsWidget> createState() => _GoogleMapsWidgetState();
}

class _GoogleMapsWidgetState extends State<GoogleMapsWidget> {
  GoogleMapController? _mapController; 

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(MapLoad());
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller; 
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listener: (context, state) {
        if (state is MapLoaded && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(state.position),
          );
        }
      },
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is MapLoaded) {
            return GoogleMap(
              onMapCreated: _onMapCreated, 
              initialCameraPosition: CameraPosition(
                target: state.position,
                zoom: 15,
              ),
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              myLocationEnabled: true, 
              myLocationButtonEnabled: false, 
            );
          } else if (state is MapError) {
            return const Center(child: Text('Error loading map'));
          }
          return const Center(child: Text('Application Error'));
        },
      ),
    );
  }
}
