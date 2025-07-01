part of 'dashboard_tasklist_bloc.dart';

@immutable
sealed class DashboardTasklistEvent {}
final class DashboardTasklistInitialfetchingEvent extends DashboardTasklistEvent{}