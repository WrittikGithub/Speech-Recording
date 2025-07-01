part of 'bottom_navigationbar_bloc.dart';

@immutable
sealed class BottomNavigationbarEvent {}

final class NavigateToPageEvent extends BottomNavigationbarEvent {
  final int pageIndex;

  NavigateToPageEvent({required this.pageIndex});
}
