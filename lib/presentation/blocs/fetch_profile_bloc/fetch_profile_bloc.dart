import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/user_profile_model.dart';
import 'package:sdcp_rebuild/domain/repositories/profilerepo.dart';


part 'fetch_profile_event.dart';
part 'fetch_profile_state.dart';

class FetchProfileBloc extends Bloc<FetchProfileEvent, FetchProfileState> {
  final Profilerepo repository;
  FetchProfileBloc({required this.repository}) : super(FetchProfileInitial()) {
    on<FetchProfileEvent>((event, emit) {});
    on<FetchProfileInitialEvent>(fetchprofileevent);
  }

  FutureOr<void> fetchprofileevent(
      FetchProfileInitialEvent event, Emitter<FetchProfileState> emit) async {
    emit(FetchProfileLoadingState());
    final response = await repository.fetchuserprofile();
    if (!response.error && response.status == 200) {
      emit(FetchProfileSuccessState(userdatas: response.data!));
    } else {
      emit(FetchProfileErrorState(message: response.message));
    }
  }
          @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
