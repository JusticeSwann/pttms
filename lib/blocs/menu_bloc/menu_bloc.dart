import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(const SelectedIndexState(selectedIndex: 0)) {
    on<MenuItemSelected>((event, emit) {
      emit (SelectedIndexState(selectedIndex: event.selectedIndex));
    });
  }
}
