import 'dart:async';


import 'package:bloc/bloc.dart';

import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/comment_model.dart';

import 'package:sdcp_rebuild/domain/repositories/commentrepo.dart';

part 'fetch_comment_event.dart';
part 'fetch_comment_state.dart';

class FetchCommentBloc extends Bloc<FetchCommentEvent, FetchCommentState> {
  final Commentrepo repository;
  FetchCommentBloc({required this.repository}) : super(FetchCommentInitial()) {
    on<FetchCommentEvent>((event, emit) {});
    on<FetchCommentInitialEvent>(fetchcommentevent);
  }

  FutureOr<void> fetchcommentevent(
      FetchCommentInitialEvent event, Emitter<FetchCommentState> emit) async {
    emit(FetchCommmentLoadingState());
    final response = await repository.fetchcomment(
        taskTargetId: event.taskTargetId, contentId: event.contentId);
    if (!response.error && response.status == 200) {
    
      emit(FetchCommentSuccessState(comments: response.data!));
    } else {
      emit(FetchCommentErrorState(message: response.message));
    }
  }

  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
