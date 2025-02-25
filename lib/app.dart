import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/menu_bloc/menu_bloc.dart';
import 'package:pttms/blocs/route_bloc/route_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc.dart';
import 'package:pttms/data/repository/routes_repository.dart';
import 'package:pttms/data/services/route_detection_service.dart';
import 'package:pttms/presentation/screens/home_page.dart';
import 'package:pttms/presentation/screens/routes_page.dart';
import 'package:pttms/presentation/widgets/bottom_navbar_widget.dart';

/// The screens you want to display in your bottom navigation.
List<Widget> pages = [
  const HomePage(),
  const RoutesPage(),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Provide your repositories/services
        RepositoryProvider(create: (context) => LocationRepository()),
        RepositoryProvider(create: (context) => RouteDetectionService()),
        RepositoryProvider(
          create: (context) => RoutesRepository(
            routeDetectionService: context.read<RouteDetectionService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // Provide your blocs
          BlocProvider(create: (context) => MenuBloc()),
          BlocProvider(
            create: (context) => MapBloc(
              locationRepository: context.read<LocationRepository>(),
            )..add(MapLoad()), // Dispatch MapLoad on creation
          ),
          BlocProvider(create: (context) => RouteBloc()),
          // Provide the RouteTrackingBloc so HomePage can find it.
          BlocProvider(
            create: (context) => RouteTrackingBloc(
              routesRepository: context.read<RoutesRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: BlocBuilder<MenuBloc, MenuState>(
                builder: (context, state) {
                  if (state is SelectedIndexState) {
                    return pages[state.selectedIndex];
                  }
                  // Default to the first page if no index is selected
                  return pages[0];
                },
              ),
            ),
            bottomNavigationBar: const BottomNavBarWidget(),
          ),
        ),
      ),
    );
  }
}
