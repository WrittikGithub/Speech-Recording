import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';

part 'save_task_event.dart';
part 'save_task_state.dart';

class SaveTaskBloc extends Bloc<SaveTaskEvent, SaveTaskState> {
  final Taskrepo repository;
  SaveTaskBloc({required this.repository}) : super(SaveTaskInitial()) {
    on<SaveTaskEvent>((event, emit) {});
    on<SaveTaskButtonclickingEvent>(savebuttonclikevent);
  }

  FutureOr<void> savebuttonclikevent(
      SaveTaskButtonclickingEvent event, Emitter<SaveTaskState> emit) async {
    emit(SaveTaskLoadingState());
    final response = await repository.saveTask(taskRecord: event.saveData);
    if (!response.error && response.status == 200) {
      emit(SaveTaskSuccessState(message: response.message));
    } else {
      emit(SaveTaskErrorState(response.message));
    }
  }
}
