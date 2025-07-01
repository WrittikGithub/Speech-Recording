part of 'dashboard_data_bloc.dart';

@immutable
sealed class DashboardDataState {}

final class DashboardDataInitial extends DashboardDataState {}

final class DashboardDataLoadingState extends DashboardDataState {}

final class DashboardDataSuccessState extends DashboardDataState {
  final DashboardDatamodel dashboardDatas;

  DashboardDataSuccessState({required this.dashboardDatas});
}

final class DashboardDataErrorState extends DashboardDataState {
  final String message;

  DashboardDataErrorState({required this.message});
}
