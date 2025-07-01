import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/reportmodel.dart';
import 'package:sdcp_rebuild/domain/repositories/dashboardrepo.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final Dashbordrepo repository;
  ReportBloc({required this.repository}) : super(ReportInitial()) {
    on<ReportEvent>((event, emit) {});
    on<ReportFetchingButtonclickingEvent>(reportfetchingevent);
  }

  FutureOr<void> reportfetchingevent(ReportFetchingButtonclickingEvent event,
      Emitter<ReportState> emit) async {
    emit(ReportFetchingLoadingState());
    final response = await repository.fetchreport(fromDate: event.fromdate, toDate: event.toDate);
    if (!response.error && response.status == 200) {
      emit(ReportFetchingSuccessState(report: response.data!));
    } else {
      emit(ReportFetchingErorrState(message: response.message));
    }
  }
}
