import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  RouteBloc() : super(const RouteVehicleState(vehicleType: [true,false,false], vehicleTypeIndex: 0)) {

    on<VehicleTypeSelected>((event, emit) {
      _onVehicleTypeSelected(event,emit);
    });

  }
  void _onVehicleTypeSelected(VehicleTypeSelected event, Emitter<RouteState> emit) {
    List<bool> updatedVehicleType = List.generate(
      event.vehicleType.length,
      (index) => index == event.vehicleTypeIndex,
    );
    emit(RouteVehicleState(vehicleType: updatedVehicleType, vehicleTypeIndex: event.vehicleTypeIndex));
  }

  
}


