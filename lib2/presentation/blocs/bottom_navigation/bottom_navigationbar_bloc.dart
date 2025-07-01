import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'bottom_navigationbar_event.dart';
part 'bottom_navigationbar_state.dart';

class BottomNavigationbarBloc
    extends Bloc<BottomNavigationbarEvent, BottomNavigationbarState> {
  BottomNavigationbarBloc() : super(const BottomNavigationbarInitial()) {
    on<BottomNavigationbarEvent>((event, emit) {});
    on<NavigateToPageEvent>(_navigateToPage);
  }

  FutureOr<void> _navigateToPage(
      NavigateToPageEvent event, Emitter<BottomNavigationbarState> emit) {
    emit(NavigationState(currentPageIndex: event.pageIndex));
  }
}
