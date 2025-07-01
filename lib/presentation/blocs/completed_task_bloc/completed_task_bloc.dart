import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/completed_taskmodel.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';

part 'completed_task_event.dart';
part 'completed_task_state.dart';

class CompletedTaskBloc extends Bloc<CompletedTaskEvent, CompletedTaskState> {
  final Taskrepo repository;
  List<CompletedTaskmodel> alltasks = [];
  CompletedTaskBloc({required this.repository})
      : super(CompletedTaskInitial()) {
    on<CompletedTaskEvent>((event, emit) {});
    on<CompletedTaskInitialFetchingEvent>(completedtaskevent);
    on<CompletedTaskSearchEvent>(searchtask);
    on<CompletedTaskFilterEvent>(filterevent);
  }

  FutureOr<void> completedtaskevent(CompletedTaskInitialFetchingEvent event,
      Emitter<CompletedTaskState> emit) async {
    emit(CompletedTaskLoadingState());
    final response = await repository.fetchcompletedtask();
    if (!response.error && response.status == 200) {
      alltasks = response.data!;
      emit(CompletedTskSuccessState(completedtasks: response.data!));
    } else {
      emit(CompletedTaskErrorState(message: response.message));
    }
  }

  FutureOr<void> searchtask(
      CompletedTaskSearchEvent event, Emitter<CompletedTaskState> emit) async {
    if (event.query.isEmpty) {
      emit(CompletedTskSuccessState(completedtasks: alltasks));
      return;
    }
    final searchresults = alltasks
        .where((task) => task.taskTargetId
            .toLowerCase()
            .contains(event.query.toLowerCase()))
        .toList();

    if (searchresults.isEmpty) {
      emit(CompletedTaskSearchState(searchresults: const []));
    } else {
      emit(CompletedTaskSearchState(searchresults: searchresults));
    }
  }

  FutureOr<void> filterevent(
      CompletedTaskFilterEvent event, Emitter<CompletedTaskState> emit) {
    List<CompletedTaskmodel> filterdTasks = List.from(alltasks);
    if (event.language != null) {
      filterdTasks = filterdTasks
          .where((task) =>
              task.languageName.toLowerCase() == event.language!.toLowerCase())
          .toList();
    }
    if (event.status != null) {
      filterdTasks = filterdTasks
          .where((task) =>
              task.status.toLowerCase() == event.status!.toLowerCase())
          .toList();
    }
    if (filterdTasks.isEmpty) {
      emit(CompletedTaskFilterState(filteredtasks: const []));
    } else {
      emit(CompletedTaskFilterState(filteredtasks: filterdTasks));
    }
  }
}
