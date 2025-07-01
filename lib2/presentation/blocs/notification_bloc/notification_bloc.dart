import 'dart:async';


import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/notification_model.dart';
import 'package:sdcp_rebuild/domain/repositories/dashboardrepo.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final Dashbordrepo repository;
  NotificationBloc({required this.repository}) : super(NotificationInitial()) {
    on<NotificationEvent>((event, emit) {});
    on<NotificationFetchingInitialEvent>(notificationfetchingeven);
  }

  FutureOr<void> notificationfetchingeven(
      NotificationFetchingInitialEvent event,
      Emitter<NotificationState> emit) async {
    emit(NotificationFetchingLoadingState());
    final response = await repository.fetchnotification();
    if (!response.error && response.status == 200) {
      emit(NotificationFetchingSuccessState(notifications: response.data!));
    } else {
      emit(NotificationFetchingErrorState(message: response.message));
    }
  }
}
