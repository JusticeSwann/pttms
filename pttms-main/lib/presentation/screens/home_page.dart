import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/presentation/widgets/google_maps_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const GoogleMapsWidget(

      ),
      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return FloatingActionButton(
            onPressed: () {
              context.read<MapBloc>().add(MapLoad());
            },
            shape: const CircleBorder(),
            child: const Icon(Icons.location_pin),
          );
        },
      ),
    );
  }
}
