// test/movement_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/blocs/movement_bloc/movement_bloc.dart';
import 'package:pttms/blocs/movement_bloc/movement_event.dart';
import 'package:pttms/blocs/movement_bloc/movement_state.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:pttms/data/services/route_detection_service.dart';

/// A Fake implementation of TrafficService for testing.
class FakeTrafficService extends Fake implements TrafficService {
  @override
  Future<Map<String, dynamic>> fetchTrafficData({
    required LatLng origin,
    required LatLng destination,
    required int departureTime,
  }) async {
    return {
      'raw_duration': 100,
      'traffic_duration': 120,
    };
  }

  @override
  String determineTrafficLevel({
    required int rawDuration,
    required int trafficDuration,
  }) {
    return 'low';
  }
}

/// A Fake implementation of RouteDetectionService for testing.
class FakeRouteDetectionService extends Fake implements RouteDetectionService {
  @override
  Future<Map<String, double>> getDualDistances(LatLng position, {String trafficLevel = 'low'}) async {
    // Return distances exceeding the 30-meter threshold.
    return {
      'rawDistance': 35.0,
      'trafficDistance': 35.0,
    };
  }
}

void main() {
  group('MovementBloc Tests', () {
    late MovementBloc movementBloc;
    late FakeTrafficService fakeTrafficService;
    late FakeRouteDetectionService fakeRouteDetectionService;

    setUp(() {
      fakeTrafficService = FakeTrafficService();
      fakeRouteDetectionService = FakeRouteDetectionService();
      // Default offRouteDuration can be long for other tests.
      movementBloc = MovementBloc(
        trafficService: fakeTrafficService,
        routeDetectionService: fakeRouteDetectionService,
      );
    });

    tearDown(() {
      movementBloc.close();
    });

    test('initial state is MovementInitial', () {
      expect(movementBloc.state, equals(const MovementInitial()));
    });

    blocTest<MovementBloc, MovementState>(
      'emits MovementWaiting when InitializeWaiting is added',
      build: () => movementBloc,
      act: (bloc) => bloc.add(InitializeWaiting(
        deviceId: 'test_device',
        routeId: 1,
        routeName: 'Test Route',
        startedWaiting: DateTime(2023, 1, 1, 12, 0, 0),
      )),
      expect: () => [
        MovementWaiting(
          startedWaiting: DateTime(2023, 1, 1, 12, 0, 0),
          waitingTime: 0,
        ),
      ],
    );

    blocTest<MovementBloc, MovementState>(
      'transitions from MovementWaiting to MovementActive when speed exceeds threshold',
      build: () => movementBloc,
      seed: () => MovementWaiting(
        startedWaiting: DateTime(2023, 1, 1, 12, 0, 0),
        waitingTime: 10,
      ),
      act: (bloc) => bloc.add(const UpdateLocation(
        newLocation: LatLng(10.0, 20.0),
        speed: 16.0,
        onRoute: true,
        isWalking: false,
      )),
      expect: () => [
        isA<MovementActive>(),
      ],
      verify: (bloc) {
        final state = bloc.state as MovementActive;
        expect(state.activeTime, equals(0));
        expect(state.startedTraveling, isA<DateTime>());
      },
    );

    blocTest<MovementBloc, MovementState>(
      'increments waitingTime when speed is below threshold in MovementWaiting state',
      build: () => movementBloc,
      seed: () => MovementWaiting(
        startedWaiting: DateTime(2023, 1, 1, 12, 0, 0),
        waitingTime: 0,
      ),
      act: (bloc) => bloc.add(const UpdateLocation(
        newLocation: LatLng(10.0, 20.0),
        speed: 10.0,
        onRoute: true,
        isWalking: false,
      )),
      expect: () => [
        MovementWaiting(
          startedWaiting: DateTime(2023, 1, 1, 12, 0, 0),
          waitingTime: 5,
        ),
      ],
    );

    test('emits MovementFalsePositive after off-route duration in MovementActive state', () async {
      // For this test, create a new MovementBloc with a short offRouteDuration.
      final testBloc = MovementBloc(
        trafficService: fakeTrafficService,
        routeDetectionService: fakeRouteDetectionService,
        offRouteDuration: const Duration(milliseconds: 100),
      );
      // Seed the bloc into a MovementActive state.
      testBloc.emit(MovementActive(
        startedTraveling: DateTime(2023, 1, 1, 12, 0, 0),
        activeTime: 0,
        routeTrace: const [],
        stopsMade: const [],
      ));

      // Dispatch an UpdateLocation event with onRoute set to false.
      testBloc.add(const UpdateLocation(
        newLocation: LatLng(10.0, 20.0),
        speed: 16.0,
        onRoute: false,
        isWalking: false,
      ));

      // Wait for a duration longer than the offRouteDuration.
      await Future.delayed(const Duration(milliseconds: 200));
      expect(testBloc.state, isA<MovementFalsePositive>());
      await testBloc.close();
    });
  });
}
