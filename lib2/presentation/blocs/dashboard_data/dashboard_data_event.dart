part of 'dashboard_data_bloc.dart';

@immutable
sealed class DashboardDataEvent {}
final class DashboardDataInitialFetchingEvent extends DashboardDataEvent{}