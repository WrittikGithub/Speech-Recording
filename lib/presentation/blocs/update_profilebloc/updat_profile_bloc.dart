import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/domain/repositories/profilerepo.dart';

part 'updat_profile_event.dart';
part 'updat_profile_state.dart';

class UpdatProfileBloc extends Bloc<UpdatProfileEvent, UpdatProfileState> {
  final Profilerepo repository;
  UpdatProfileBloc({required this.repository}) : super(UpdatProfileInitial()) {
    on<UpdatProfileEvent>((event, emit) {});
    on<UpdateProfileButtonClickingEvent>(updateprofileevent);
  }

  FutureOr<void> updateprofileevent(UpdateProfileButtonClickingEvent event,
      Emitter<UpdatProfileState> emit) async {
    emit(UpdateProfileLoadingState());
    final response =
        await repository.updateprofile(event.userfullName!, event.userEmail!,event.username!);
    if (!response.error && response.status == 200) {
      emit(UpdateProfileSuccessState(message: response.message));
    } else {
      emit(UpdateProfileErrorState(message: response.message));
    }
  }
}
