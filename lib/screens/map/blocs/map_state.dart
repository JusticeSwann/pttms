/*
//import 'package:equatable/equatable.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';

//class MapState extends Equatable{
//  const MapState();

//  @override
//  List<Object> get props => [];
}

class MapInitial extends MapState{}

class MapLoading extends MapState{}

class MapLoaded extends MapState{
  final LatLng position;

  const MapLoaded(this.position);
  @override
  List<Object> get props => [position];
}

class MapError extends  MapState{
  final String message;
  
  const MapError(this.message);
  @override
  List<Object> get props => [message];
}

*/