part of 'route_card_bloc.dart';

sealed class RouteCardState extends Equatable {
  const RouteCardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is received.
final class RouteCardInitial extends RouteCardState {
  const RouteCardInitial();
}

/// Loaded state contains the average wait time (in seconds), a formatted last‑updated time,
/// and the route name. (ETA is set to "-" since when vehicles are active, ETA is not computed.)
final class RouteCardLoaded extends RouteCardState {
  final int averageWaitTime; // in seconds
  final String lastUpdated;  // e.g. "10:05 AM"
  final String eta;          // ETA string (always "-" if active)
  final String routeName;

  const RouteCardLoaded({
    required this.averageWaitTime,
    required this.lastUpdated,
    required this.eta,
    required this.routeName,
  });

  @override
  List<Object?> get props => [averageWaitTime, lastUpdated, eta, routeName];
}
