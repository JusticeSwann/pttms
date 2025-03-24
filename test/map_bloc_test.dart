// test/map_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pttms/blocs/map_bloc/map_bloc.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';
import 'package:pttms/data/repository/active_vehicle_stream_repository.dart';
import 'package:pttms/data/services/route_detection_service.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/services/ticker.dart';

/// Define a fake for LatLng so that mocktail can use it as a fallback.
class FakeLatLng extends Fake implements LatLng {}

/// Create mock classes for all dependencies.
class MockLocationRepository extends Mock implements LocationRepository {}
class MockVehicleTrackingRepository extends Mock implements VehicleTrackingRepository {}
class MockRouteDetectionService extends Mock implements RouteDetectionService {}
class MockTicker extends Mock implements Ticker {}
class MockActiveVehicleStreamRepository extends Mock implements ActiveVehicleStreamRepository {}

void main() {
  // Register fallback for LatLng.
  setUpAll(() {
    registerFallbackValue(FakeLatLng());
  });

  // Declare our mocks.
  late MockLocationRepository locationRepository;
  late MockVehicleTrackingRepository vehicleTrackingRepository;
  late MockRouteDetectionService routeDetectionService;
  late MockTicker ticker;
  late MockActiveVehicleStreamRepository activeVehicleStreamRepository;

  // Helper function to build MapBloc.
  MapBloc buildBloc() {
    return MapBloc(
      deviceId: 'testDevice',
      locationRepository: locationRepository,
      vehicleTrackingRepository: vehicleTrackingRepository,
      routeDetectionService: routeDetectionService,
      ticker: ticker,
      activeVehicleStreamRepository: activeVehicleStreamRepository,
    );
  }

  setUp(() {
    locationRepository = MockLocationRepository();
    vehicleTrackingRepository = MockVehicleTrackingRepository();
    routeDetectionService = MockRouteDetectionService();
    ticker = MockTicker();
    activeVehicleStreamRepository = MockActiveVehicleStreamRepository();

    // Stub trackLocationUpdates() to return an empty stream.
    when(() => locationRepository.trackLocationUpdates()).thenAnswer(
      (_) => Stream.empty(),
    );

    // Stub getCurrentLocation() to return a valid position (can be overridden in tests).
    when(() => locationRepository.getCurrentLocation())
        .thenAnswer((_) async => const LatLng(10.0, 20.0));

    // Stub ticker.tick() to emit a periodic stream.
    when(() => ticker.tick()).thenAnswer(
      (_) => Stream.periodic(const Duration(seconds: 1), (count) => count + 1),
    );

    // Stub routeDetectionService.findNearbyRoutes to always return a valid route.
    when(() => routeDetectionService.findNearbyRoutes(any()))
        .thenAnswer((_) async => 'Curepe-Chaguanas');

    // Stub routeDetectionService.loadRoutesFromJson to return a dummy list.
    when(() => routeDetectionService.loadRoutesFromJson())
        .thenAnswer((_) async => [
              {'name': 'Curepe-Chaguanas'},
            ]);

    // IMPORTANT: Stub isNearRoute so it returns true (and not null) for any call.
    when(() => routeDetectionService.isNearRoute(any(), distanceThreshold: any(named: 'distanceThreshold')))
        .thenReturn(true);

    // Stub vehicleTrackingRepository.uploadVehicleData to succeed.
    when(() => vehicleTrackingRepository.uploadVehicleData(
          docId: any(named: 'docId'),
          deviceId: any(named: 'deviceId'),
          routeId: any(named: 'routeId'),
          routeName: any(named: 'routeName'),
          activeTime: any(named: 'activeTime'),
          waitingTime: any(named: 'waitingTime'),
          speed: any(named: 'speed'),
          status: any(named: 'status'),
          lastLocation: any(named: 'lastLocation'),
          routeTrace: any(named: 'routeTrace'),
          stopsMade: any(named: 'stopsMade'),
          pickupPoint: any(named: 'pickupPoint'),
          userOnRoute: any(named: 'userOnRoute'),
          gpsAccuracy: any(named: 'gpsAccuracy'),
          distanceTraveled: any(named: 'distanceTraveled'),
          weekendIndicator: any(named: 'weekendIndicator'),
          weatherConditions: any(named: 'weatherConditions'),
          trafficConditions: any(named: 'trafficConditions'),
          startedWaiting: any(named: 'startedWaiting'),
          startedTraveling: any(named: 'startedTraveling'),
          stoppedTraveling: any(named: 'stoppedTraveling'),
          totalCommuteTime: any(named: 'totalCommuteTime'),
          totalWaitTime: any(named: 'totalWaitTime'),
          dateTime: any(named: 'dateTime'),
          trafficLevel: any(named: 'trafficLevel'),
          averageTrafficLevel: any(named: 'averageTrafficLevel'),
        )).thenAnswer((_) async {});

    // Stub activeVehicleStreamRepository to return a stream with one vehicle.
    when(() => activeVehicleStreamRepository.streamActiveVehicleLocations(any()))
        .thenAnswer((_) => Stream.value([
              VehicleLocationData(
                lastLocation: const LatLng(1.0, 2.0),
                waitTime: 10,
                stopsMade: [],
              ),
            ]));
  });

  group('MapBloc', () {
    blocTest<MapBloc, MapState>(
      'emits [MapLoading, MapLoaded] on MapLoad success',
      build: () {
        when(() => locationRepository.getCurrentLocation())
            .thenAnswer((_) async => const LatLng(10.0, 20.0));
        // Ensure trackLocationUpdates returns an empty stream.
        when(() => locationRepository.trackLocationUpdates()).thenAnswer(
          (_) => Stream.empty(),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(MapLoad()),
      expect: () => [
        MapLoading(),
        const MapLoaded(
          position: LatLng(10.0, 20.0),
          routeTrace: [],
          activeVehicleLocations: [],
        ),
      ],
      verify: (_) {
        verify(() => locationRepository.getCurrentLocation()).called(1);
      },
    );

    blocTest<MapBloc, MapState>(
      'emits [MapLoading, MapError] on MapLoad failure',
      build: () {
        when(() => locationRepository.getCurrentLocation())
            .thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(MapLoad()),
      expect: () => [
        MapLoading(),
        const MapError('Location permission denied or unavailable.'),
      ],
    );

    blocTest<MapBloc, MapState>(
      'updates position when MoveToCurrentLocation is added',
      build: () {
        when(() => locationRepository.getCurrentLocation())
            .thenAnswer((_) async => const LatLng(12.0, 34.0));
        // Ensure trackLocationUpdates returns an empty stream.
        when(() => locationRepository.trackLocationUpdates()).thenAnswer(
          (_) => Stream.empty(),
        );
        return buildBloc();
      },
      seed: () => const MapLoaded(
        position: LatLng(0, 0),
        routeTrace: [],
        activeVehicleLocations: [],
      ),
      act: (bloc) => bloc.add(MoveToCurrentLocation()),
      expect: () => [
        const MapLoaded(
          position: LatLng(12.0, 34.0),
          routeTrace: [],
          activeVehicleLocations: [],
        ),
      ],
      verify: (_) {
        verify(() => locationRepository.getCurrentLocation()).called(1);
      },
    );

    blocTest<MapBloc, MapState>(
      'subscribes to active vehicle stream and updates after 5 ticks',
      build: () {
        // Override ticker to emit 6 ticks quickly.
        when(() => ticker.tick()).thenAnswer((_) => Stream.fromIterable([1, 2, 3, 4, 5, 6]));
        when(() => activeVehicleStreamRepository.streamActiveVehicleLocations(any()))
            .thenAnswer((_) => Stream.value([
                  VehicleLocationData(
                    lastLocation: const LatLng(1.0, 2.0),
                    waitTime: 10,
                    stopsMade: [],
                  ),
                ]));
        // Ensure trackLocationUpdates returns an empty stream.
        when(() => locationRepository.trackLocationUpdates()).thenAnswer(
          (_) => Stream.empty(),
        );
        return buildBloc();
      },
      seed: () => const MapLoaded(
        position: LatLng(0, 0),
        routeTrace: [],
        activeVehicleLocations: [],
      ),
      act: (bloc) => bloc.add(const StartActiveVehicleStream('Curepe-Chaguanas')),
      expect: () => [
        // After tick 5, the bloc should emit a new state with updated activeVehicleLocations.
        isA<MapLoaded>().having(
          (s) => s.activeVehicleLocations,
          'activeVehicleLocations',
          isNotEmpty,
        ),
      ],
      verify: (_) {
        verify(() => activeVehicleStreamRepository.streamActiveVehicleLocations('Curepe-Chaguanas')).called(1);
      },
    );
  });
}
