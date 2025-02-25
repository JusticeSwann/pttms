import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/presentation/widgets/google_maps_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          bool showPolyline = true;
          if (state is MapLoadedWithRoute) {
            showPolyline = state.showPolyline;
          }
          return GoogleMapsWidget(showPolyline: showPolyline);
        },
      ),
      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          List<Widget> buttons = [
            FloatingActionButton(
              heroTag: 'currentLocation',
              onPressed: () {
                context.read<MapBloc>().add(MoveToCurrentLocation());
              },
              child: const Icon(Icons.my_location),
            ),
          ];
          
          if (state is MapLoadedWithRoute && state.isOnRoute) {
            buttons.add(const SizedBox(height: 10));
            buttons.add(
              FloatingActionButton(
                heroTag: 'togglePolyline',
                onPressed: () {
                  context.read<MapBloc>().add(TogglePolyline());
                },
                child: Icon(
                  state.showPolyline ? Icons.visibility : Icons.visibility_off,
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
