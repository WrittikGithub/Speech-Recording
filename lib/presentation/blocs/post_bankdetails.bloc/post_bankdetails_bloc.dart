import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/postbank_details_model.dart';
import 'package:sdcp_rebuild/domain/repositories/bankrepo.dart';


part 'post_bankdetails_event.dart';
part 'post_bankdetails_state.dart';

class PostBankdetailsBloc
    extends Bloc<PostBankdetailsEvent, PostBankdetailsState> {
  final Bankrepo repository;
  PostBankdetailsBloc({required this.repository})
      : super(PostBankdetailsInitial()) {
    on<PostBankdetailsEvent>((event, emit) {});
    on<PostBankdetailsButtonClickEvent>(postbankdetailsevent);
  }

  FutureOr<void> postbankdetailsevent(PostBankdetailsButtonClickEvent event,
      Emitter<PostBankdetailsState> emit) async {
    emit(PostBankdetailsLoadingState());
    final response =
        await repository.postBankdetails(bankdetails: event.bankdetails);
    if (!response.error && response.status == 200) {
      emit(PostBankdetailsSuccessState(message: response.message));
    } else {
      emit(PostBankdetailsErrorState(message: response.message));
    }
  }
         @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
