// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/blocs/menu_bloc/menu_bloc.dart';
import 'package:pttms/blocs/movement_bloc/movement_bloc.dart';
import 'package:pttms/blocs/route_bloc/route_bloc.dart';
import 'package:pttms/blocs/route_tracking_bloc/route_tracking_bloc.dart';
import 'package:pttms/data/repository/routes_repository.dart';
import 'package:pttms/data/services/route_detection_service.dart';
import 'package:pttms/presentation/screens/home_page.dart';
import 'package:pttms/presentation/screens/routes_page.dart';
import 'package:pttms/presentation/widgets/bottom_navbar_widget.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pttms/services/notification_service.dart';
import 'package:pttms/services/notification_service.dart' show flutterLocalNotificationsPlugin;

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
        RepositoryProvider(create: (context) => LocationRepository()),
        RepositoryProvider(
          create: (context) => TrafficService(apiKey: 'YOUR_GOOGLE_API_KEY_HERE'),
        ),
        RepositoryProvider(create: (context) => RouteDetectionService()),
        RepositoryProvider(
          create: (context) => RoutesRepository(
            routeDetectionService: context.read<RouteDetectionService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MenuBloc()),
          BlocProvider(
            create: (context) => MovementBloc(
              trafficService: context.read<TrafficService>(),
              routeDetectionService: context.read<RouteDetectionService>(),
            ),
          ),
          BlocProvider(
            create: (context) => MapBloc(
              locationRepository: context.read<LocationRepository>(),
            )..add(MapLoad()),
          ),
          BlocProvider(create: (context) => RouteBloc()),
          BlocProvider(
            create: (context) => RouteTrackingBloc(
              routesRepository: context.read<RoutesRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<RouteTrackingBloc, RouteTrackingState>(
                    listener: (context, trackingState) {
                      _handleTrackingStateChange(trackingState);
                    },
                  ),
                ],
                child: BlocBuilder<MenuBloc, MenuState>(
                  builder: (context, state) {
                    if (state is SelectedIndexState) {
                      return pages[state.selectedIndex];
                    }
                    return pages[0];
                  },
                ),
              ),
            ),
            bottomNavigationBar: const BottomNavBarWidget(),
          ),
        ),
      ),
    );
  }

  void _handleTrackingStateChange(RouteTrackingState state) {
    if (state is RouteTrackingLoaded) {
      Workmanager().registerPeriodicTask(
        "backgroundTracking",
        "backgroundTrackingTask",
        frequency: const Duration(minutes: 15),
      );
      showPersistentNotification();
    } else {
      Workmanager().cancelByUniqueName("backgroundTracking");
      flutterLocalNotificationsPlugin.cancel(0);
    }
  }
}
