part of 'dashboard_tasklist_bloc.dart';

@immutable
sealed class DashboardTasklistState {}

final class DashboardTasklistInitial extends DashboardTasklistState {}

final class DashboardTasklistLoadingState extends DashboardTasklistState {}

final class DashboardTasklistSuccessState extends DashboardTasklistState {
  final List<DashboardTaskModel> tasklist;

  DashboardTasklistSuccessState({required this.tasklist});
}

final class DashboardTasklistErrorState extends DashboardTasklistState {
  final String message;

  DashboardTasklistErrorState({required this.message});
}
