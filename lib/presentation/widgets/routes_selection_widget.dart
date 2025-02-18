import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/route_bloc/route_bloc.dart';

class RoutesSelectionWidget extends StatelessWidget {
  const RoutesSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<RouteBloc, RouteState>(
          builder: (context, state) {
            if (state is RoutesLoading){
              const CircularProgressIndicator();
            }
            return const DropdownMenu(
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 1, label: 'label')
              ],
              leadingIcon: Icon(Icons.location_pin),
              width: 300,
              hintText: 'Select route',
            );
          },
        ),
        BlocBuilder<RouteBloc, RouteState>(
          builder: (context, state) {
            if (state is RouteVehicleState) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 100,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      isSelected: state.vehicleType,
                      borderRadius: BorderRadius.circular(40),
                      onPressed: (int index) {
                        context.read<RouteBloc>().add(VehicleTypeSelected(
                            vehicleTypeIndex: index,
                            vehicleType: state.vehicleType));
                      },
                      fillColor: Colors.transparent,
                      selectedColor: Colors.red,
                      highlightColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      selectedBorderColor: Colors.transparent,
                      children: const [
                        Icon(
                          Icons.directions_bus,
                          size: 35,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 35,
                        ),
                      ],
                    )
                  ],
                ),
              );
            } else {
              return const SizedBox(); //Might want to replace this later.
            }
          },
        ),
      ],
    );
  }
}
