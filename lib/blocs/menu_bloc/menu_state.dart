part of 'menu_bloc.dart';

sealed class MenuState extends Equatable {
  const MenuState();
  
  @override
  List<Object> get props => [];
}

class SelectedIndexState extends MenuState{
  final int selectedIndex;
  const SelectedIndexState({required this.selectedIndex});

  @override
  List<Object> get props => [selectedIndex];
}

final class MenuBlocInitial extends MenuState {}
