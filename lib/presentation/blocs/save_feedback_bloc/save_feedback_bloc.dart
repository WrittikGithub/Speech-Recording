import 'dart:async';


import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';

part 'save_feedback_event.dart';
part 'save_feedback_state.dart';

class SaveFeedbackBloc extends Bloc<SaveFeedbackEvent, SaveFeedbackState> {
  final Reviewsrepo repository;
  SaveFeedbackBloc({required this.repository}) : super(SaveFeedbackInitial()) {
    on<SaveFeedbackEvent>((event, emit) {});
    on<SaveFeedbackButtonClickingEvent>(savefeedbackevent);
  }

  FutureOr<void> savefeedbackevent(SaveFeedbackButtonClickingEvent event,
      Emitter<SaveFeedbackState> emit) async {
    emit(SaveFeedbackLoadingState());
    final response = await repository.savefeedback(
        taskTargetId: event.taskTargetId,
        additionalinformation: event.additionalinfo);
    if (!response.error && response.status == 200) {
      emit(SaveFeedbackSuccessState());
    } else {
      emit(SaveFeedbackErrorState(message:response.message));
    }
  }
}
