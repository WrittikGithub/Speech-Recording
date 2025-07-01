import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'bottom_navigationbar_event.dart';
part 'bottom_navigationbar_state.dart';

class BottomNavigationbarBloc
    extends Bloc<BottomNavigationbarEvent, BottomNavigationbarState> {
  BottomNavigationbarBloc() : super(const BottomNavigationbarInitial()) {
    on<BottomNavigationbarEvent>((event, emit) {});
    on<NavigateTo>((event, emit) {
      emit(NavigationState(currentPageIndex: event.index));
    });
    
    on<NavigateToPageEvent>(_navigateToPage);
  }

  FutureOr<void> _navigateToPage(
      NavigateToPageEvent event, Emitter<BottomNavigationbarState> emit) {
    print("NAVIGATION BLOC: Navigating to page ${event.pageIndex}");
    emit(NavigationState(currentPageIndex: event.pageIndex));
  }
}

class NavigateTo extends BottomNavigationbarEvent {
  final int index;
  
  NavigateTo(this.index);
  
  @override
  List<Object> get props => [index];
}
