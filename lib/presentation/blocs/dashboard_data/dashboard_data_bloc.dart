import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/dashboard_datamodel.dart';
import 'package:sdcp_rebuild/domain/repositories/dashboardrepo.dart';


part 'dashboard_data_event.dart';
part 'dashboard_data_state.dart';

class DashboardDataBloc extends Bloc<DashboardDataEvent, DashboardDataState> {
  final Dashbordrepo repository;
  DashboardDataBloc({required this.repository})
      : super(DashboardDataInitial()) {
    on<DashboardDataEvent>((event, emit) {
     
    });
     on<DashboardDataInitialFetchingEvent>(fetchdashboardData);
  }

  FutureOr<void> fetchdashboardData(DashboardDataInitialFetchingEvent event,
      Emitter<DashboardDataState> emit) async {
    emit(DashboardDataLoadingState());
    final response =await repository.fetchdashborddata();
     if (!response.error && response.status == 200) {
        emit(DashboardDataSuccessState(dashboardDatas: response.data!));
      } else {
        emit(DashboardDataErrorState(message: response.message));
      }
  }
      @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
