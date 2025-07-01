import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:sdcp_rebuild/domain/repositories/commentrepo.dart';

part 'save_comment_event.dart';
part 'save_comment_state.dart';

class SaveCommentBloc extends Bloc<SaveCommentEvent, SaveCommentState> {
  final Commentrepo repository;
  SaveCommentBloc({required this.repository}) : super(SaveCommentInitial()) {
    on<SaveCommentEvent>((event, emit) {});
    on<SaveCommentButtonClickingEvent>(savecommentevent);
  }

  FutureOr<void> savecommentevent(SaveCommentButtonClickingEvent event,
      Emitter<SaveCommentState> emit) async {
    emit(SaveCommentLoadingState());
    final response = await repository.savechcomment(
        taskTargetId: event.taskTargetId,
        contentId: event.contentId,
        comment: event.comment);
    if (!response.error && response.status == 200) {
      emit(SaveCommentSuccessState());
    } else {
      emit(SaveCommentErrorState(message: response.message));
    }
  }
}
