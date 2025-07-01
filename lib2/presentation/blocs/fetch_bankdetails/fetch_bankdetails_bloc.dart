import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/bankdetails_model.dart';

import 'package:sdcp_rebuild/domain/repositories/bankrepo.dart';

part 'fetch_bankdetails_event.dart';
part 'fetch_bankdetails_state.dart';

class FetchBankdetailsBloc
    extends Bloc<FetchBankdetailsEvent, FetchBankdetailsState> {
  final Bankrepo repository;
  FetchBankdetailsBloc({required this.repository})
      : super(FetchBankdetailsInitial()) {
    on<FetchBankdetailsEvent>((event, emit) {});
    on<FetchbnakdetailsInitialEvent>(fetchbankdetailsevent);
  }

  FutureOr<void> fetchbankdetailsevent(FetchbnakdetailsInitialEvent event,
      Emitter<FetchBankdetailsState> emit) async {
    emit(FetchBankdetailsLoadingState());
    final response = await repository.fetchuserbankdetails();
    if (!response.error && response.status == 200) {
      emit(FetchBankdetailsSuccessState(bankdetails: response.data!));
    } else {
      emit(FetchBankdetailsErrorState(message: response.message));
    }
  }
}
