// lib/blocs/route_card_bloc/route_card_state.dart
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
  final int averageWaitTime; // in seconds
  final String lastUpdated;  // formatted "HH:MM AM/PM"
  final String eta;          // For now, always "-"
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
