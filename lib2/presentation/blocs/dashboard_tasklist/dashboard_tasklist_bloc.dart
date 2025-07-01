import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/dashbord_taskmodel.dart';

import 'package:sdcp_rebuild/domain/repositories/dashboardrepo.dart';

part 'dashboard_tasklist_event.dart';
part 'dashboard_tasklist_state.dart';

class DashboardTasklistBloc
    extends Bloc<DashboardTasklistEvent, DashboardTasklistState> {
  final Dashbordrepo repository;
  DashboardTasklistBloc({required this.repository})
      : super(DashboardTasklistInitial()) {
    on<DashboardTasklistEvent>((event, emit) {});
    on<DashboardTasklistInitialfetchingEvent>(dashboardtasklistfetching);
  }

  FutureOr<void> dashboardtasklistfetching(
      DashboardTasklistInitialfetchingEvent event,
      Emitter<DashboardTasklistState> emit) async {
    emit(DashboardTasklistLoadingState());
    final response = await repository.fetchdashbordtask();
    if (!response.error && response.status == 200) {
      emit(DashboardTasklistSuccessState(tasklist: response.data!));
    } else {
      emit(DashboardTasklistErrorState(message: response.message));
    }
  }
        @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
