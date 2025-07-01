part of 'report_bloc.dart';

@immutable
sealed class ReportState {}

final class ReportInitial extends ReportState {}

final class ReportFetchingLoadingState extends ReportState {}

final class ReportFetchingSuccessState extends ReportState {
  final Reportmodel report;

  ReportFetchingSuccessState({required this.report});
}

final class ReportFetchingErorrState extends ReportState {
  final String message;

  ReportFetchingErorrState({required this.message});
}
