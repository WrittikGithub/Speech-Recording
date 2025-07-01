import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/comment_model.dart';
import 'package:sdcp_rebuild/domain/repositories/commentrepo.dart';

part 'review_comment_event.dart';
part 'review_comment_state.dart';

class ReviewCommentBloc extends Bloc<ReviewCommentEvent, ReviewCommentState> {
  final Commentrepo repository;
  ReviewCommentBloc({required this.repository})
      : super(ReviewCommentInitial()) {
    on<ReviewCommentEvent>((event, emit) {});
    on<FetchReviewCommentInitialEvent>(fetchreviewcommentevent);
  }

  FutureOr<void> fetchreviewcommentevent(FetchReviewCommentInitialEvent event,
      Emitter<ReviewCommentState> emit) async {
    emit(FetchReviewCommmentLoadingState());
    final response = await repository.fetchreviewcomment(
        taskTargetId: event.taskTargetId, contentId: event.contentId);
    if (!response.error && response.status == 200) {
    
      emit(FetchReviewCommentSuccessState(comments: response.data!));
    } else {
      emit(FetchReviewCommentErrorState(message: response.message));
    }
  }
    @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
