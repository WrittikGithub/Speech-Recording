import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/instruction_model.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';


part 'fetch_instructions_event.dart';
part 'fetch_instructions_state.dart';

class FetchInstructionsBloc
    extends Bloc<FetchInstructionsEvent, FetchInstructionsState> {
  final Reviewsrepo repository;
  FetchInstructionsBloc({required this.repository})
      : super(FetchInstructionsInitial()) {
    on<FetchInstructionsEvent>((event, emit) {});
    on<FetchingInstructionsInitialEvent>(fetchinstructionsevent);
  }

  FutureOr<void> fetchinstructionsevent(FetchingInstructionsInitialEvent event,
      Emitter<FetchInstructionsState> emit) async {
    emit(FetchInstructionsLoadingState());
    final response =
        await repository.fetchinstruction(contentId: event.contentId);
    if (!response.error && response.status == 200) {
      emit(FetchInstructionsSuccessState(instructions: response.data!));
    } else {
      emit(FetchInstructionsErrorState(message:response.message));
    }
  }

  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
