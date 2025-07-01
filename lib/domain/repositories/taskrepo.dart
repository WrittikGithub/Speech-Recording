import 'dart:async';
import 'dart:convert';
import 'dart:developer';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/completed_taskmodel.dart';
import 'package:sdcp_rebuild/data/content_model.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/data/task_model.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/domain/databases/save_task_databasehelper.dart';
import 'package:sdcp_rebuild/domain/databases/task_database_helper.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
import 'package:sdcp_rebuild/presentation/widgets/syncprogress_class.dart';

class ApiResponse<T> {
  final T? data;
  final String message;
  final bool error;
  final int status;

  ApiResponse({
    this.data,
    required this.message,
    required this.error,
    required this.status,
  });
}

class Taskrepo {
  final http.Client client;
  //////////////
  final DatabaseHelper dbHelper;
  final ContentDatabaseHelper contentDbHelper;
  final SaveTaskDatabasehelper saveTaskDbHelper;
  // Timer? _syncTimer;
  // bool _isSyncing = false;
  //bool _wasConnected = true;
  Taskrepo({http.Client? client})
      : client = client ?? http.Client(),
        dbHelper = DatabaseHelper(),
        contentDbHelper = ContentDatabaseHelper(),
        saveTaskDbHelper = SaveTaskDatabasehelper();
  //        {
  //   // Start periodic sync
  //   startPeriodicSync();
  // }

  // void startPeriodicSync() {
  //   _syncTimer?.cancel();
  //   _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
  //     syncWithServer();
  //   });
  // }

  Future<void> syncWithServer() async {
    // if (_isSyncing) return;
    // _isSyncing = true;

    try {
      // Sync tasks first
      final taskApiResponse = await fetchtask();
      if (!taskApiResponse.error && taskApiResponse.data != null) {
        await dbHelper.clearAllTasks();
        await dbHelper.insertTasks(taskApiResponse.data!);

        // // Then sync contents for each task
        // for (var task in taskApiResponse.data!) {
        //   await syncContentsForTask(task.taskTargetId);
        // }
      }
    } catch (e) {
      debugPrint('Sync error: ${e.toString()}');
    } finally {
      // _isSyncing = false;
    }
  }

  Future<void> syncContentsForTask(String taskTargetId) async {
    try {
    
      final apiResponse = await _fetchContentsFromApi(taskTargetId);
      if (!apiResponse.error && apiResponse.data != null) {
        await contentDbHelper.deleteContentsByTaskTargetId(taskTargetId);
        await contentDbHelper.insertContents(apiResponse.data!);
        print('updated contents for task $taskTargetId');
      }
    } catch (e) {
      debugPrint('Content sync error for task $taskTargetId: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TaskModel>>> fetchtask() async {
    try {
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.task}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<TaskModel> tasklist =
            jsonList.map((json) => TaskModel.fromJson(json)).toList();
        return ApiResponse(
          data: tasklist,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred',
        error: true,
        status: 500,
      );
    }
  }

  Future<List<TaskModel>> getLocalTasks() async {
    return await dbHelper.getAllTasks();
  }

  ///////
  // Taskrepo({http.Client? client}) : client = client ?? http.Client();
  // Future<ApiResponse<List<TaskModel>>> fetchtask() async {
  //   try {
  //     final token = await getUserToken();
  //     var response = await client.post(
  //       Uri.parse('${Endpoints.baseurl}${Endpoints.task}'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization':token
  //       },
  //     );

  //     final responseData = jsonDecode(response.body);
  //     if (!responseData["error"] && responseData["status"] == 200) {
  //        final List<dynamic> jsonList = responseData['data'];
  //       final List<TaskModel> tasklist =
  //           jsonList.map((json) => TaskModel.fromJson(json)).toList();
  //       return ApiResponse(
  //         data: tasklist,
  //         message: responseData['message'] ?? 'Success',
  //         error: false,
  //         status: responseData["status"],
  //       );
  //     } else {
  //       return ApiResponse(
  //         data: null,
  //         message: responseData['message'] ?? 'Something went wrong',
  //         error: true,
  //         status: responseData["status"],
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //     log(e.toString());
  //     return ApiResponse(
  //       data: null,
  //       message: 'Network or server error occurred',
  //       error: true,
  //       status: 500,
  //     );
  //   }
  // }
  Future<ApiResponse<List<ContentModel>>> _fetchContentsFromApi(
      String taskTargetId) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.contentwithTasktargetId}?taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<ContentModel> contentlist =
            jsonList.map((json) => ContentModel.fromJson(json)).toList();

        return ApiResponse(
          data: contentlist,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred',
        error: true,
        status: 500,
      );
    }
  }

  ///////-----------------contentswithtasktargetId-----------////////////////
  ///online preference///////////////
  Future<ApiResponse<List<ContentModel>>> fetchContentsWithTaskTargetId({
    required String taskTargetId,
  }) async {
  
    // If network is available, always fetch from online
      final hasNetwork = await NetworkChecker.hasNetwork();
    if (hasNetwork) {
      try {
        final token = await getUserToken();
        var response = await client.get(
          Uri.parse(
              '${Endpoints.baseurl}${Endpoints.contentwithTasktargetId}?taskTargetId=$taskTargetId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        );

        final responseData = jsonDecode(response.body);
        if (!responseData["error"] && responseData["status"] == 200) {
          final List<dynamic> jsonList = responseData['data'];
          final List<ContentModel> contentList =
              jsonList.map((json) => ContentModel.fromJson(json)).toList();

          return ApiResponse(
            data: contentList,
            message: responseData['message'] ?? 'Success',
            error: false,
            status: responseData["status"],
          );
        } else {
          return ApiResponse(
            data: null,
            message: responseData['message'] ?? 'Something went wrong',
            error: true,
            status: responseData["status"],
          );
        }
      } catch (e) {
        debugPrint(e.toString());
        return ApiResponse(
          data: null,
          message: 'Network or server error occurred',
          error: true,
          status: 500,
        );
      }
    }

    try {
      final localContents =
          await contentDbHelper.getContentsByTaskTargetId(taskTargetId);
      if (localContents.isNotEmpty) {
        return ApiResponse(
          data: localContents,
          message: 'Success (Local)',
          error: false,
          status: 200,
        );
      } else {
        return ApiResponse(
          data: null,
          message: 'No local data available',
          error: true,
          status: 404,
        );
      }
    } catch (e) {
      debugPrint('Local fetch error: ${e.toString()}');
      return ApiResponse(
        data: null,
        message: 'Error fetching local data',
        error: true,
        status: 500,
      );
    }
  }

  ///offline preference///
  // Future<ApiResponse<List<ContentModel>>> fetchcontentswithtaskTargetId(
  //     {required String taskTargetId, bool forceOnline = false}) async {
  //   // Try to get local data first if not forcing online
  //   if (!forceOnline) {
  //     try {
  //       final localContents =
  //           await contentDbHelper.getContentsByTaskTargetId(taskTargetId);
  //       if (localContents.isNotEmpty) {
  //         print('tetching from local database');
  //         return ApiResponse(
  //           data: localContents,
  //           message: 'Success (Local)',
  //           error: false,
  //           status: 200,
  //         );
  //       }
  //     } catch (e) {
  //       debugPrint('Local fetch error: ${e.toString()}');
  //     }
  //   }

  //   // If local data doesn't exist or force online, fetch from server
  //   try {
  //     final token = await getUserToken();
  //     var response = await client.get(
  //       Uri.parse(
  //           '${Endpoints.baseurl}${Endpoints.contentwithTasktargetId}?taskTargetId=$taskTargetId'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': token,
  //       },
  //     );

  //     final responseData = jsonDecode(response.body);
  //     if (!responseData["error"] && responseData["status"] == 200) {
  //       final List<dynamic> jsonList = responseData['data'];
  //       final List<ContentModel> contentlist =
  //           jsonList.map((json) => ContentModel.fromJson(json)).toList();

  //       return ApiResponse(
  //         data: contentlist,
  //         message: responseData['message'] ?? 'Success',
  //         error: false,
  //         status: responseData["status"],
  //       );
  //     } else {
  //       return ApiResponse(
  //         data: null,
  //         message: responseData['message'] ?? 'Something went wrong',
  //         error: true,
  //         status: responseData["status"],
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //     return ApiResponse(
  //       data: null,
  //       message: 'Network or server error occurred',
  //       error: true,
  //       status: 500,
  //     );
  //   }
  // }
//   Future<ApiResponse<List<ContentModel>>> fetchcontentswithtaskTargetId({required String taskTargetId}) async {
//     try {
//       final token = await getUserToken();
//     var response = await client.get(
//   Uri.parse('${Endpoints.baseurl}${Endpoints.contentwithTasktargetId}?taskTargetId=$taskTargetId'),
//   headers: {
//     'Content-Type': 'application/json',
//     'Authorization': token,
//   },
// );

//       final responseData = jsonDecode(response.body);
//       if (!responseData["error"] && responseData["status"] == 200) {
//          final List<dynamic> jsonList = responseData['data'];
//         final List<ContentModel> contentlist =
//             jsonList.map((json) => ContentModel.fromJson(json)).toList();
//         return ApiResponse(
//           data:contentlist,
//           message: responseData['message'] ?? 'Success',
//           error: false,
//           status: responseData["status"],
//         );
//       } else {
//         return ApiResponse(
//           data: null,
//           message: responseData['message'] ?? 'Something went wrong',
//           error: true,
//           status: responseData["status"],
//         );
//       }
//     } catch (e) {
//       debugPrint(e.toString());
//       log(e.toString());
//       return ApiResponse(
//         data: null,
//         message: 'Network or server error occurred',
//         error: true,
//         status: 500,
//       );
//     }
//   }
///////////////////--------submittask------///////////
  Future<ApiResponse> saveTask({required SubmitTaskModel taskRecord}) async {
    try {
      // Add print to debug network status
      final hasNetwork = await NetworkChecker.hasNetwork();
      print("NetworkChecker reports network available: $hasNetwork");
      
      // Use the isForceOnline flag to bypass network check if needed
      if (taskRecord.isForceOnline) {
        print("Forcing online mode for this submission");
        // Skip network check and proceed as if online
      } else if (!hasNetwork) {
        // Store task locally if no network and not forcing online
        await saveTaskDbHelper.insertPendingTask(taskRecord);
        return ApiResponse(
          data: null,
          message: 'Task saved offline',
          error: false,
          status: 200,
        );
      }
      
      // If network available, proceed with API call
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.savetask}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(taskRecord),
      );

      final responseData = jsonDecode(response.body);
      log(response.body);

      if (!responseData["error"] && responseData["status"] == 200) {
       // await syncContentsForTask(taskRecord.taskTargetId);
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        // Store task locally if API call fails
        await saveTaskDbHelper.insertPendingTask(taskRecord);
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      // Store task locally if any error occurs
      await saveTaskDbHelper.insertPendingTask(taskRecord);
      debugPrint(e.toString());
      log(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred',
        error: true,
        status: 500,
      );
    }
  }

  /////////////////
  // Future<void> syncPendingTasks() async {
  //   if (!await NetworkChecker.hasNetwork()) return;

  //   final pendingTasks = await saveTaskDbHelper.getPendingTasks();

  //   for (var task in pendingTasks) {
  //     try {
  //       final result = await saveTask(taskRecord: task);
  //       if (!result.error) {
  //         await saveTaskDbHelper.deletePendingTask(
  //             task.contentId, task.taskTargetId);
  //       }
  //     } catch (e) {
  //       log('Error syncing task: ${e.toString()}');
  //       continue;
  //     }
  //   }
  // }
    Future<void> syncPendingTasks() async {
    if (!await NetworkChecker.hasNetwork()) return;
    
    final pendingTasks = await saveTaskDbHelper.getPendingTasks();
    if (pendingTasks.isEmpty) return;

    SyncProgress().startSync(pendingTasks.length);

    for (var task in pendingTasks) {
      try {
        final result = await saveTask(taskRecord: task);
        if (!result.error) {
          await saveTaskDbHelper.deletePendingTask(
              task.contentId, task.taskTargetId);
        }
        SyncProgress().updateProgress();
      } catch (e) {
        log('Error syncing task: ${e.toString()}');
        continue;
      }
    }
    
    SyncProgress().completeSync();
  }
  // Future<ApiResponse> saveTask({required SubmitTaskModel taskRecord}) async {
  //   try {
  //     final token = await getUserToken();
  //     var response = await client.post(
  //       Uri.parse('${Endpoints.baseurl}${Endpoints.savetask}'),
  //       headers: {'Content-Type': 'application/json', 'Authorization': token},
  //       body: jsonEncode(taskRecord),
  //     );

  //     final responseData = jsonDecode(response.body);
  //     log(response.body);
  //     if (!responseData["error"] && responseData["status"] == 200) {
  //       await syncContentsForTask(taskRecord.taskTargetId);
  //       return ApiResponse(
  //         data: null,
  //         message: responseData['message'] ?? 'Success',
  //         error: false,
  //         status: responseData["status"],
  //       );
  //     } else {
  //       return ApiResponse(
  //         data: null,
  //         message: responseData['message'] ?? 'Something went wrong',
  //         error: true,
  //         status: responseData["status"],
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //     log(e.toString());
  //     return ApiResponse(
  //       data: null,
  //       message: 'Network or server error occurred',
  //       error: true,
  //       status: 500,
  //     );
  //   }
  // }

  //////////---------fetch completedtask--------/////////////////////////
  Future<ApiResponse<List<CompletedTaskmodel>>> fetchcompletedtask() async {
    try {
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.completedTask}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<CompletedTaskmodel> completedtasklist =
            jsonList.map((json) => CompletedTaskmodel.fromJson(json)).toList();
        return ApiResponse(
          data: completedtasklist,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      log(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred',
        error: true,
        status: 500,
      );
    }
  }

/////////////---------------////////////////////////
  Future<ApiResponse> submitTask({required String taskTargetId}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.submittask}?taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      log(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred',
        error: true,
        status: 500,
      );
    }
  }

  // Comment out or remove these methods
  /*
  Future<bool> checkContentHasAudio(String contentId) async {
    // removed code
  }

  Future<String?> downloadAudioContent({
    required String contentId,
    required String taskTargetId,
  }) async {
    // removed code
  }
  */

  void dispose() {
    // _syncTimer?.cancel();
    client.close();
  }
}
