import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/language_model.dart';

import 'package:sdcp_rebuild/domain/repositories/languagerepo.dart';

part 'user_language_event.dart';
part 'user_language_state.dart';

class UserLanguageBloc extends Bloc<UserLanguageEvent, UserLanguageState> {
  final Languagerepo repository;
  UserLanguageBloc({required this.repository}) : super(UserLanguageInitial()) {
    on<UserLanguageEvent>((event, emit) {});
    on<UserLanguageFetchingEvent>(userlanguagefetching);
  }

  FutureOr<void> userlanguagefetching(
      UserLanguageFetchingEvent event, Emitter<UserLanguageState> emit) async {
            if (state is! UserLanguageSuccessState) {
      emit(UserLanguageLoadingState());
      final response = await repository.fetchuserlanguage();
      if (!response.error && response.status == 200) {
        emit(UserLanguageSuccessState(userlangauges: response.data!));
      } else {
        emit(UserLanguageErrorState(message: response.message));
      }
    }
  }

  //   emit(UserLanguageLoadingState());
  //   final response = await repository.fetchuserlanguage();
  //   if (!response.error && response.status == 200) {
  //     emit(UserLanguageSuccessState(userlangauges: response.data!));
  //   } else {
  //     emit(UserLanguageErrorState(message: response.message));
  //   }
  // }
          @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
