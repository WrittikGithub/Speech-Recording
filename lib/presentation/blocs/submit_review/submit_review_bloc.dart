import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';

part 'submit_review_event.dart';
part 'submit_review_state.dart';

class SubmitReviewBloc extends Bloc<SubmitReviewEvent, SubmitReviewState> {
  final Reviewsrepo repository;
  SubmitReviewBloc({required this.repository}) : super(SubmitReviewInitial()) {
    on<SubmitReviewEvent>((event, emit) {});
    on<SubmitReviewButtonClickEvent>(submitreview);
  }

  FutureOr<void> submitreview(SubmitReviewButtonClickEvent event,
      Emitter<SubmitReviewState> emit) async {
    emit(SubmitReviewLoadingState());
    final response =
        await repository.submitReview(taskTargetId: event.taskTargetId);
    if (!response.error && response.status == 200) {
      emit(SubmitReviewSuccessState(message: response.message));
    } else {
      emit(SubmitReviewErrorState(message: response.message));
    }
  }
}
