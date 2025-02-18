/*

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';


class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => LocationRepository(),
      child: BlocProvider(
        create: (context) => MapBloc(
          locationRepository: context.read<LocationRepository>(),
        )..add(LoadMap()),
        child: Scaffold(
          body: BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              if (state is MapLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is MapLoaded) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: state.position,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                );
              } else if (state is MapError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else {
                return const Center(
                  child: Text('Initializing...'),
                );
              }
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/routes'); // Navigate to RoutesPage
            },
            child: const Icon(Icons.directions),
          ),
        ),
      ),
    );
  }
}
*/