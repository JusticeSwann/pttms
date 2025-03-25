import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';
import 'package:pttms/data/repository/active_vehicle_stream_repository.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:pttms/services/ticker.dart';
import 'package:pttms/utils/time_utils.dart'; // e.g. formatTime()

part 'route_card_event.dart';
part 'route_card_state.dart';

/// This bloc listens to active vehicle data for a single route and computes
/// the average wait time (from the vehicles’ waitTime values) as well as the last updated timestamp.
/// Since the stream only contains active vehicles, ETA is always set to "-".
class RouteCardBloc extends Bloc<RouteCardEvent, RouteCardState> {
  final String routeName;
  final ActiveVehicleStreamRepository activeVehicleStreamRepository;
  final TrafficService trafficService; // (Not used for wait time here but available for ETA if needed)
  final Ticker ticker;

  StreamSubscription<List<VehicleLocationData>>? _vehicleSubscription;
  StreamSubscription<int>? _tickerSubscription;

  RouteCardBloc({
    required this.routeName,
    required this.activeVehicleStreamRepository,
    required this.trafficService,
    required this.ticker,
  }) : super(const RouteCardInitial()) {
    on<RouteCardStart>(_onStart);
    on<RouteCardVehiclesUpdated>(_onVehiclesUpdated);

    // Optional: Refresh every 5 seconds.
    _tickerSubscription = ticker.tick().listen((tickCount) {
      if (tickCount % 5 == 0) {
        add(const RouteCardStart());
      }
    });
  }

  Future<void> _onStart(RouteCardStart event, Emitter<RouteCardState> emit) async {
    // Cancel any existing subscription.
    await _vehicleSubscription?.cancel();

    // Subscribe to active vehicle data for the given route.
    _vehicleSubscription = activeVehicleStreamRepository
        .streamActiveVehicleLocations(routeName)
        .listen((vehicles) {
      add(RouteCardVehiclesUpdated(vehicles));
    });
  }

  void _onVehiclesUpdated(RouteCardVehiclesUpdated event, Emitter<RouteCardState> emit) {
    final vehicles = event.vehicles;

    int averageWaitSec = 0;
    if (vehicles.isNotEmpty) {
      final totalWait = vehicles.fold<int>(0, (sum, v) => sum + v.waitTime);
      averageWaitSec = totalWait ~/ vehicles.length;
    }
    final now = DateTime.now();
    final lastUpdatedStr = formatTime(now); // e.g. "10:05 AM"

    // Since all vehicles are active, ETA is set to "-"
    const eta = "-";

    emit(RouteCardLoaded(
      averageWaitTime: averageWaitSec,
      lastUpdated: lastUpdatedStr,
      eta: eta,
      routeName: routeName,
    ));
  }

  @override
  Future<void> close() {
    _vehicleSubscription?.cancel();
    _tickerSubscription?.cancel();
    return super.close();
  }
}
