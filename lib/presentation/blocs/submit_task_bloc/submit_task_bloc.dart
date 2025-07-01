import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';

part 'submit_task_event.dart';
part 'submit_task_state.dart';

class SubmitTaskBloc extends Bloc<SubmitTaskEvent, SubmitTaskState> {
  final Taskrepo repository;
  SubmitTaskBloc({required this.repository}) : super(SubmitTaskInitial()) {
    on<SubmitTaskEvent>((event, emit) {});
    on<SubmitTaskButtonClickEvent>(submittask);
  }

  FutureOr<void> submittask(
      SubmitTaskButtonClickEvent event, Emitter<SubmitTaskState> emit) async {
    emit(SubmitTaskLoadingState());
    final response =
        await repository.submitTask(taskTargetId: event.taskTargetId);
    if (!response.error && response.status == 200) {
      emit(SubmitTaskSuccessState(message: response.message));
    } else {
      emit(SubmitTaskErrorState(message: response.message));
    }
  }
}
