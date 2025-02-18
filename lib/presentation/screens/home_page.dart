import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/presentation/widgets/google_maps_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showPolyline = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMapsWidget(showPolyline: _showPolyline),
      floatingActionButton: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          List<Widget> buttons = [
            // "Get Current Location" Floating Button
            FloatingActionButton(
              heroTag: 'currentLocation',
              onPressed: () {
                context.read<MapBloc>().add(MoveToCurrentLocation());
              },
              child: const Icon(Icons.my_location),
            ),
          ];
          
          if (state is MapLoadedWithRoute && state.isOnRoute) {
            buttons.add(const SizedBox(height: 10)); // Spacing between buttons.
            buttons.add(
              FloatingActionButton(
                heroTag: 'togglePolyline',
                onPressed: () {
                  setState(() {
                    _showPolyline = !_showPolyline;
                  });
                },
                child: Icon(
                  _showPolyline ? Icons.visibility : Icons.visibility_off,
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
