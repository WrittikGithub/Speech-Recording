import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/review_content_model.dart';

import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';

part 'review_content_event.dart';
part 'review_content_state.dart';

class ReviewContentBloc extends Bloc<ReviewContentEvent, ReviewContentState> {
  final Reviewsrepo repository;
  ReviewContentBloc({required this.repository})
      : super(ReviewContentInitial()) {
    on<ReviewContentEvent>((event, emit) {});
    on<ReviewContentFetchingInitialEvent>(fetchreviewcontent);
    on<ReviewContentDownloadingEvent>(downloadreviewcontent);
  }

  FutureOr<void> fetchreviewcontent(ReviewContentFetchingInitialEvent event,
      Emitter<ReviewContentState> emit) async {
    emit(ReviewContentLoadingState());
    final response =
        await repository.fetchcreviewcontent(taskTargetId: event.taskTargetId);
    if (!response.error && response.status == 200) {
      emit(ReviewContentSuccessState(contentlist: response.data!));
    } else {
      emit(ReviewContentErrrorState(message: response.message));
    }
  }
  

  FutureOr<void> downloadreviewcontent(ReviewContentDownloadingEvent event, Emitter<ReviewContentState> emit)async {
try {
  emit(ReviewContentDownloadingState(
    contentTaskTargetId: event.taskTargetId
  ));
  await repository.syncReviewContentsForTask(event.taskTargetId);
  emit(ReviewContentDownloadSuccessState(
    contentTaskTargetId: event.taskTargetId
  ));
} catch (e) {
  emit(ReviewContentErrrorState(
    message: 'Download failed',
    contentTaskTargetId: event.taskTargetId
  ));
}

  }
         @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
