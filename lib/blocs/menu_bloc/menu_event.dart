part of 'menu_bloc.dart';

sealed class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object> get props => [];
}

class MenuItemSelected extends MenuEvent{
  final int selectedIndex;
  const MenuItemSelected({required this.selectedIndex});

  @override
  List<Object> get props => [selectedIndex];
}



