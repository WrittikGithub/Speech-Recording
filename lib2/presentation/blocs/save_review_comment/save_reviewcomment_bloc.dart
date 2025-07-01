import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/domain/repositories/commentrepo.dart';

part 'save_reviewcomment_event.dart';
part 'save_reviewcomment_state.dart';

class SaveReviewcommentBloc extends Bloc<SaveReviewcommentEvent, SaveReviewcommentState> {
  final Commentrepo repository;
  SaveReviewcommentBloc({required this.repository}) : super(SaveReviewcommentInitial()) {
    on<SaveReviewcommentEvent>((event, emit) {
      
    });
    on<SaveReviewCommentButtonClickingEvent>(savereviewcommentevent);
  }

  FutureOr<void> savereviewcommentevent(SaveReviewCommentButtonClickingEvent event, Emitter<SaveReviewcommentState> emit) async{
       emit(SaveReviewCommentLoadingState());
    final response = await repository.savereviewcomment(
        taskTargetId: event.taskTargetId,
        contentId: event.contentId,
        comment: event.comment);
    if (!response.error && response.status == 200) {
      emit(SaveReviewCommentSuccessState());
    } else {
      emit(SaveReviewCommentErrorState(message: response.message));
    }
  }
}
