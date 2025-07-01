part of 'completed_task_bloc.dart';

@immutable
sealed class CompletedTaskState {}

final class CompletedTaskInitial extends CompletedTaskState {}

final class CompletedTaskLoadingState extends CompletedTaskState {}

final class CompletedTskSuccessState extends CompletedTaskState {
  final List<CompletedTaskmodel> completedtasks;

  CompletedTskSuccessState({required this.completedtasks});
}

final class CompletedTaskErrorState extends CompletedTaskState {
  final String message;

  CompletedTaskErrorState({required this.message});
}

final class CompletedTaskSearchState extends CompletedTaskState {
  final List<CompletedTaskmodel> searchresults;

  CompletedTaskSearchState({required this.searchresults});
}

final class CompletedTaskFilterState extends CompletedTaskState {
  final List<CompletedTaskmodel> filteredtasks;

  CompletedTaskFilterState({required this.filteredtasks});
}
