part of 'completed_task_bloc.dart';

@immutable
sealed class CompletedTaskEvent {}

final class CompletedTaskInitialFetchingEvent extends CompletedTaskEvent {}

final class CompletedTaskSearchEvent extends CompletedTaskEvent {
  final String query;

  CompletedTaskSearchEvent({required this.query});
}

final class CompletedTaskFilterEvent extends CompletedTaskEvent {
  final String? language;
  final String? status;

  CompletedTaskFilterEvent({required this.language, required this.status});
}
