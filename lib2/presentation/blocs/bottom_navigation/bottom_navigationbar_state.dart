part of 'bottom_navigationbar_bloc.dart';

@immutable
sealed class BottomNavigationbarState {
  final int currentPageIndex;

  const BottomNavigationbarState({required this.currentPageIndex});
}

final class BottomNavigationbarInitial extends BottomNavigationbarState {
  const BottomNavigationbarInitial() : super(currentPageIndex: 0);
}

final class NavigationState extends BottomNavigationbarState {
  const NavigationState({required super.currentPageIndex});
}
