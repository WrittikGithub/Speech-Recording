import 'dart:async';


import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/task_model.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';


part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final Taskrepo repository;
  List<TaskModel> allTasks = [];
  TaskBloc({required this.repository}) : super(TaskInitial()) {
    on<TaskEvent>((event, emit) {});
   // on<TaskFetchingInitialEvent>(taskfetching);
    on<TaskSerachEvent>(searchtask);
    on<TaskFilterEvent>(filtertask);
    ////
     on<TaskRefreshEvent>(refreshTasks);
     on<TaskFetchingInitialEvent>(_checkAndLoadTasks);
      on<TaskDownloadEvent>(downloadTasks);
  }

  // FutureOr<void> taskfetching(
  //     TaskFetchingInitialEvent event, Emitter<TaskState> emit) async {
  //   emit(TaskFetchingLoadingState());
  //   final response = await repository.fetchtask();
  //   if (!response.error && response.status == 200) {
  //       final filteredTasks = response.data!.where((task) =>
  //       task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
  //     allTasks =filteredTasks;
  //   emit(TaskFetchingSuccessState(tasks: filteredTasks));
    
     
  //   } else {
  //     emit(TaskFetchingErrorState(message: response.message));
  //   }
  // }
//////////2//////////////
//  FutureOr<void> taskfetching(
//       TaskFetchingInitialEvent event, Emitter<TaskState> emit) async {
//     emit(TaskFetchingLoadingState());
    
//     try {
    
//       // First try to load from local database
//       final localTasks = await repository.getLocalTasks();
//       if (localTasks.isNotEmpty) {
//         log('loaded from local database');
//         final filteredTasks = localTasks.where((task) =>
//             task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
//         allTasks = filteredTasks;
//         emit(TaskFetchingSuccessState(tasks: filteredTasks));
//       }

//       // Then try to sync with server
//       await repository.syncWithServer();
      
//       // Reload from local database after sync
//       final updatedTasks = await repository.getLocalTasks();
//       final filteredTasks = updatedTasks.where((task) =>
//           task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
//       allTasks = filteredTasks;
//       emit(TaskFetchingSuccessState(tasks: filteredTasks));
//     } catch (e) {
//       emit(TaskFetchingErrorState(message: 'Error loading tasks: ${e.toString()}'));
//     }
//   }
 FutureOr<void> _checkAndLoadTasks(
      TaskFetchingInitialEvent event, Emitter<TaskState> emit) async {
    emit(TaskFetchingLoadingState());
    
    try {
      // First check local database
      final localTasks = await repository.getLocalTasks();
      
      if (localTasks.isNotEmpty) {
        // If we have local data, load it immediately
        final filteredTasks = localTasks.where((task) =>
            task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
        allTasks = filteredTasks;
        emit(TaskFetchingSuccessState(tasks: filteredTasks));
      } else {
        // If no local data, show download button
        emit(TaskInitial());
      }
    } catch (e) {
      emit(TaskFetchingErrorState(message: 'Error loading tasks: ${e.toString()}'));
    }
  }
 FutureOr<void> downloadTasks(TaskDownloadEvent event, Emitter<TaskState> emit) async {
    try {
      emit(TaskDownloadingState(progress: 0.0));
      
      final taskApiResponse = await repository.fetchtask();
      if (!taskApiResponse.error && taskApiResponse.data != null) {
        await repository.dbHelper.clearAllTasks();
        await repository.dbHelper.insertTasks(taskApiResponse.data!);
        
        emit(TaskDownloadingState(progress: 0.3));
        
        final totalTasks = taskApiResponse.data!.length;
        for (var i = 0; i < taskApiResponse.data!.length; i++) {
          //await repository.syncContentsForTask(taskApiResponse.data![i].taskTargetId);
          emit(TaskDownloadingState(
            progress: 0.3 + (0.7 * (i + 1) / totalTasks),
          ));
        }
        
        final localTasks = await repository.getLocalTasks();
        final filteredTasks = localTasks.where((task) =>
            task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
        allTasks = filteredTasks;
        emit(TaskFetchingSuccessState(tasks: filteredTasks));
      } else {
        emit(TaskFetchingErrorState(message: 'Failed to download tasks'));
      }
    } catch (e) {
      emit(TaskFetchingErrorState(message: 'Error downloading tasks: ${e.toString()}'));
    }
  }
  // FutureOr<void> refreshTasks(
  //     TaskRefreshEvent event, Emitter<TaskState> emit) async {
  //   emit(TaskFetchingLoadingState());
  //   await repository.syncWithServer();
  //   final updatedTasks = await repository.getLocalTasks();
  //   final filteredTasks = updatedTasks.where((task) =>
  //       task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
  //   allTasks = filteredTasks;
  //   emit(TaskFetchingSuccessState(tasks: filteredTasks));
  // }
  FutureOr<void> refreshTasks(
    TaskRefreshEvent event, Emitter<TaskState> emit) async {
  try {
    // Show initial loading state
    emit(TaskDownloadingState(progress: 0.0));
    
    // Fetch new tasks from server
    final taskApiResponse = await repository.fetchtask();
    if (!taskApiResponse.error && taskApiResponse.data != null) {
      // Clear and update local tasks
      await repository.dbHelper.clearAllTasks();
      await repository.dbHelper.insertTasks(taskApiResponse.data!);
      
      emit(TaskDownloadingState(progress: 0.3));
      
      // Sync content for each task with progress updates
      final totalTasks = taskApiResponse.data!.length;
      for (var i = 0; i < taskApiResponse.data!.length; i++) {
       // await repository.syncContentsForTask(taskApiResponse.data![i].taskTargetId);
        emit(TaskDownloadingState(
          progress: 0.3 + (0.7 * (i + 1) / totalTasks),
        ));
      }
      
      // Load updated data
      final localTasks = await repository.getLocalTasks();
      final filteredTasks = localTasks.where((task) =>
          task.status == "IN-PROGRESS" || task.status == "ASSIGNED").toList();
      allTasks = filteredTasks;
      emit(TaskFetchingSuccessState(tasks: filteredTasks));
    } else {
      emit(TaskFetchingErrorState(
        message: taskApiResponse.message 
      ));
    }
  } catch (e) {
    emit(TaskFetchingErrorState(
      message: 'Error refreshing tasks: ${e.toString()}'
    ));
  }
}
  ////////////////////
  FutureOr<void> searchtask(
      TaskSerachEvent event, Emitter<TaskState> emit) async {
    if (event.query.isEmpty) {
      emit(TaskFetchingSuccessState(tasks: allTasks));
      return;
    }
    final searchresults = allTasks
        .where((task) =>
            task.taskTargetId.toLowerCase().contains(event.query.toLowerCase()))
        .toList();
    if (searchresults.isEmpty) {
      emit(TasksearchState(searchResult: const []));
    } else {
      emit(TasksearchState(searchResult: searchresults));
    }
  }

  FutureOr<void> filtertask(TaskFilterEvent event, Emitter<TaskState> emit) {
    List<TaskModel> filterdTasks = List.from(allTasks);
    if (event.language != null) {
      filterdTasks = filterdTasks
          .where((task) =>
              task.languageName.toLowerCase() == event.language!.toLowerCase())
          .toList();
    }
    if (event.status != null) {
      filterdTasks = filterdTasks
          .where((task) =>
              task.status.toLowerCase() == event.status!.toLowerCase())
          .toList();
    }
    if (filterdTasks.isEmpty) {
      emit(TaskFilteredState(filteredTasks: const []));
    } else {
      emit(TaskFilteredState(filteredTasks: filterdTasks));
    }
  }
          @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
///////////////////
