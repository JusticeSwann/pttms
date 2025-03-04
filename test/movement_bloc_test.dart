// test/movement_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pttms/blocs/movement_bloc/movement_bloc.dart';
import 'package:pttms/blocs/movement_bloc/movement_event.dart';
import 'package:pttms/blocs/movement_bloc/movement_state.dart';
import 'package:pttms/services/traffic_service.dart';

/// A Fake implementation of TrafficService for testing purposes.
class FakeTrafficService extends Fake implements TrafficService {
  @override
  Future<Map<String, dynamic>> fetchTrafficData({
    required LatLng origin,
    required LatLng destination,
    required int departureTime,
  }) async {
    // Return stubbed data.
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

void main() {
  group('MovementBloc Tests', () {
    late MovementBloc movementBloc;
    late FakeTrafficService fakeTrafficService;

    setUp(() {
      fakeTrafficService = FakeTrafficService();
      movementBloc = MovementBloc(trafficService: fakeTrafficService);
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
      act: (bloc) => bloc.add(UpdateLocation(
        newLocation: const LatLng(10.0, 20.0),
        speed: 16.0, // above threshold
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
      act: (bloc) => bloc.add(UpdateLocation(
        newLocation: const LatLng(10.0, 20.0),
        speed: 10.0, // below threshold
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
  });
}
