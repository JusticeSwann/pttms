import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/menu_bloc/menu_bloc.dart';

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        int selectedIndex = 0; 
        if (state is SelectedIndexState) {
          selectedIndex = state.selectedIndex;
        }

        return NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions),
              label: 'Routes',
            ),
          ],
          onDestinationSelected: (int value) {
            context.read<MenuBloc>().add(MenuItemSelected(selectedIndex: value));
          },
          selectedIndex: selectedIndex,
        );
      },
    );
  }
}
