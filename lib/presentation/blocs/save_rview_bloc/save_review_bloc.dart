import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/savereview_model.dart';

import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';

part 'save_review_event.dart';
part 'save_review_state.dart';

class SaveReviewBloc extends Bloc<SaveReviewEvent, SaveReviewState> {
  final Reviewsrepo repository;
  SaveReviewBloc({required this.repository}) : super(SaveReviewInitial()) {
    on<SaveReviewEvent>((event, emit) {});
    on<SaveRviewButtonclickEvent>(savereviewevent);
  }

  FutureOr<void> savereviewevent(
      SaveRviewButtonclickEvent event, Emitter<SaveReviewState> emit) async {
    emit(SaveReviewLoadingSate());
    final response = await repository.savereview(event.reviews);
    if (!response.error && response.status == 200) {
      emit(SaveReviewSuccessState());
    } else {
      emit(SaveReviewErrorState(message: response.message));
    }
  }
}
