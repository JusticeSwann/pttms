part of 'route_card_bloc.dart';

abstract class RouteCardState extends Equatable {
  const RouteCardState();
  @override
  List<Object?> get props => [];
}

class RouteCardInitial extends RouteCardState {
  const RouteCardInitial();
}

class RouteCardLoaded extends RouteCardState {
  /// averageWaitTime is in seconds; if null, it means no data is available.
  final int? averageWaitTime;
  final String lastUpdated;   // Formatted as "HH:MM AM/PM"
  final String eta;           // The computed ETA string (e.g., "5 min" or "-" if not updated)
  final String routeName;
  /// If true, the stream returned at least one vehicle.
  final bool hasData;

  const RouteCardLoaded({
    required this.averageWaitTime,
    required this.lastUpdated,
    required this.eta,
    required this.routeName,
    required this.hasData,
  });

  @override
  List<Object?> get props => [averageWaitTime, lastUpdated, eta, routeName, hasData];
}
