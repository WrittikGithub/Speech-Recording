import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/preview_scoremodel.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';


part 'preview_score_event.dart';
part 'preview_score_state.dart';

class PreviewScoreBloc extends Bloc<PreviewScoreEvent, PreviewScoreState> {
  final Reviewsrepo repository;
  PreviewScoreBloc({required this.repository}) : super(PreviewScoreInitial()) {
    on<PreviewScoreEvent>((event, emit) {});
    on<PreviewScoreButtonClickEvent>(previewscoreevent);
  }

  FutureOr<void> previewscoreevent(PreviewScoreButtonClickEvent event,
      Emitter<PreviewScoreState> emit) async {
    emit(PreviewScoreLoadingState());
    final response =
        await repository.fetchpreviewscore(taskTargetId: event.taskTargetId);
    if (!response.error && response.status == 200) {
      emit(PreviewScoreSuccessState(previewScores: response.data!));
    } else {
      emit(PreviewScoreErrorState(message:response.message));
    }
  }
}
