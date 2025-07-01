part of 'report_bloc.dart';

@immutable
sealed class ReportEvent {}

final class ReportFetchingButtonclickingEvent extends ReportEvent {
  final String fromdate;
  final String toDate;

  ReportFetchingButtonclickingEvent({required this.fromdate, required this.toDate});
}
