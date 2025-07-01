import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/instruction_model.dart';
import 'package:sdcp_rebuild/data/preview_scoremodel.dart';
import 'package:sdcp_rebuild/data/review_content_model.dart';
import 'package:sdcp_rebuild/data/reviews_model.dart';
import 'package:sdcp_rebuild/data/savereview_model.dart';

import 'package:sdcp_rebuild/domain/databases/review_content_database_helper.dart';

import 'package:sdcp_rebuild/domain/databases/review_database_helper.dart';
import 'package:sdcp_rebuild/domain/databases/save_task_databasehelper.dart';
import 'package:sdcp_rebuild/domain/databases/savereview_databasehelper.dart';
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

class Reviewsrepo {
  final http.Client client;
  final ReviewsDatabaseHelper reviewsDatabaseHelper;
  final ReviewContentDatabaseHelper reviewContentDatabaseHelper;
  final SaveReviewDatabaseHelper saveReviewDatabaseHelper;
  Reviewsrepo({http.Client? client})
      : client = client ?? http.Client(),
        reviewsDatabaseHelper = ReviewsDatabaseHelper(),
        saveReviewDatabaseHelper=SaveReviewDatabaseHelper(),
        reviewContentDatabaseHelper = ReviewContentDatabaseHelper();
  Future<ApiResponse<List<ReviewsModel>>> fetchreviewsAsssignments() async {
    try {
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.reviewsAssignmentsonlyInterview}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<ReviewsModel> reviewslist =
            jsonList.map((json) => ReviewsModel.fromJson(json)).toList();
        return ApiResponse(
          data: reviewslist,
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

  /////////
  Future<void> syncReviewWithServer() async {
    // if (_isSyncing) return;
    // _isSyncing = true;

    try {
      // Sync tasks first
      final reviewApiResponse = await fetchreviewsAsssignments();
      if (!reviewApiResponse.error && reviewApiResponse.data != null) {
        await reviewsDatabaseHelper.clearAllReviews();
        await reviewsDatabaseHelper.insertReviews(reviewApiResponse.data!);
      }
    } catch (e) {
      debugPrint('Sync error: ${e.toString()}');
    } finally {
      // _isSyncing = false;
    }
  }

  ///
  Future<List<ReviewsModel>> getLocalReviews() async {
    return await reviewsDatabaseHelper.getAllReviews();
  }

////////-----//////////////////////////////
  Future<ApiResponse<List<InstructionDataModel>>> fetchinstruction(
      {required String contentId}) async {
    debugPrint('contenIdddd:$contentId');
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.getinstructions}?contentId=$contentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);

      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<InstructionDataModel> instructions = jsonList
            .map((json) => InstructionDataModel.fromJson(json))
            .toList();
        return ApiResponse(
          data: instructions,
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

////////////-------////////////////
  // Future<ApiResponse> savereview(SaveReviewModel reviews) async {
  //   log(reviews.contentId);
  //   log(reviews.reviewStatus);
  //   log('same${reviews.tContentId}');
  //   log(reviews.taskTargetId);

  //   try {
  //     final token = await getUserToken();
  //     var response = await client.get(
  //       Uri.parse(
  //           '${Endpoints.baseurl}${Endpoints.savereview}?${reviews.getQueryParameters()}'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': token,
  //       },
  //     );

  //     final responseData = jsonDecode(response.body);

  //     if (!responseData["error"] && responseData["status"] == 200) {
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
 Future<ApiResponse> savereview(SaveReviewModel reviews) async {
    try {
      final hasNetwork = await NetworkChecker.hasNetwork();
      if (!hasNetwork) {
        // Store review locally if no network
        await saveReviewDatabaseHelper.insertPendingReview(reviews);
           await reviewContentDatabaseHelper.updateReviewStatus(
          reviews.taskTargetId,
          reviews.contentId,
          reviews.reviewStatus,
        );
        return ApiResponse(
          data: null,
          message: 'Review saved offline',
          error: false,
          status: 200,
        );
      }

      // If network available, proceed with API call
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse('${Endpoints.baseurl}${Endpoints.savereview}?${reviews.getQueryParameters()}'),
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
        // Store review locally if API call fails
        await saveReviewDatabaseHelper.insertPendingReview(reviews);
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Something went wrong',
          error: true,
          status: responseData["status"],
        );
      }
    } catch (e) {
      // Store review locally if any error occurs
      await saveReviewDatabaseHelper.insertPendingReview(reviews);
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
  Future<void> syncPendingReviews() async {
    if (!await NetworkChecker.hasNetwork()) return;
   
    final pendingReviews = await saveReviewDatabaseHelper.getPendingReviews();
    if (pendingReviews.isEmpty) return;

    SyncProgress().startSync(pendingReviews.length);

    for (var review in pendingReviews) {
      try {
        final result = await savereview(review);
        if (!result.error) {
          await saveReviewDatabaseHelper.deletePendingReview(
            review.contentId,
            review.taskTargetId,
          );
        }
        SyncProgress().updateProgress();
      } catch (e) {
        log('Error syncing review: ${e.toString()}');
        continue;
      }
    }

    SyncProgress().completeSync();
  }
  // Future<void> syncPendingReviews() async {
  //   if (!await NetworkChecker.hasNetwork()) return;
    
  //   final pendingReviews = await saveReviewDatabaseHelper.getPendingReviews();
  //   for (var review in pendingReviews) {
  //     try {
  //       final result = await savereview(review);
  //       if (!result.error) {
  //         await saveReviewDatabaseHelper.deletePendingReview(
  //           review.contentId,
  //           review.taskTargetId,
  //         );
  //       }
  //     } catch (e) {
  //       log('Error syncing review: ${e.toString()}');
  //       continue;
  //     }
  //   }
  // }
///////////------------/////////////////
  Future<void> syncReviewContentsForTask(String taskTargetId) async {
    try {
      final apiResponse =
          await _fetchcreviewcontent(taskTargetId: taskTargetId);
      if (!apiResponse.error && apiResponse.data != null) {
        await reviewContentDatabaseHelper
            .deleteContentsByTargetTaskTargetId(taskTargetId);
        print('deleted for task $taskTargetId');
        await reviewContentDatabaseHelper
            .insertReviewContents(apiResponse.data!);
        print('updated contents for task $taskTargetId');
      }
    } catch (e) {
      debugPrint('Content sync error for task $taskTargetId: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<ReviewContentModel>>> _fetchcreviewcontent({
    required String taskTargetId,
  }) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.reviewcontents}?taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);

      if (!responseData["error"] && responseData["status"] == 200) {
        // Parse the nested JSON data
        final List<dynamic> jsonList = responseData['data']['contents'];
        final List<ReviewContentModel> reviewcontentlist =
            jsonList.map((json) => ReviewContentModel.fromJson(json)).toList();

        return ApiResponse(
          data: reviewcontentlist,
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

  Future<ApiResponse<List<ReviewContentModel>>> fetchcreviewcontent({
    required String taskTargetId,
  }) async {
    final hasNetwork = await NetworkChecker.hasNetwork();
    if (hasNetwork) {
      try {
        final token = await getUserToken();
        var response = await client.get(
          Uri.parse(
              '${Endpoints.baseurl}${Endpoints.reviewcontents}?taskTargetId=$taskTargetId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token,
          },
        );

        final responseData = jsonDecode(response.body);

        if (!responseData["error"] && responseData["status"] == 200) {
          // Parse the nested JSON data
          final List<dynamic> jsonList = responseData['data']['contents'];
          final List<ReviewContentModel> reviewcontentlist = jsonList
              .map((json) => ReviewContentModel.fromJson(json))
              .toList();

          return ApiResponse(
            data: reviewcontentlist,
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
    try {
      final localContents = await reviewContentDatabaseHelper
          .getContentsByTargetTaskTargetId(taskTargetId);
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

  // Future<ApiResponse<List<ReviewContentModel>>> fetchcreviewcontent({
  //   required String taskTargetId,
  // }) async {
  //   try {
  //     final token = await getUserToken();
  //     var response = await client.get(
  //       Uri.parse(
  //           '${Endpoints.baseurl}${Endpoints.reviewcontents}?taskTargetId=$taskTargetId'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': token,
  //       },
  //     );

  //     final responseData = jsonDecode(response.body);

  //     if (!responseData["error"] && responseData["status"] == 200) {
  //       // Parse the nested JSON data
  //       final List<dynamic> jsonList = responseData['data']['contents'];
  //       final List<ReviewContentModel> reviewcontentlist =
  //           jsonList.map((json) => ReviewContentModel.fromJson(json)).toList();

  //       return ApiResponse(
  //         data: reviewcontentlist,
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

//////////----------------//////////////////
  Future<ApiResponse<List<PreviewScoremodel>>> fetchpreviewscore(
      {required String taskTargetId}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.previewscore}?taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<PreviewScoremodel> scorelist =
            jsonList.map((json) => PreviewScoremodel.fromJson(json)).toList();
        return ApiResponse(
          data: scorelist,
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

  //////////////---------------//////////////////////
  Future<ApiResponse> savefeedback(
      {required String taskTargetId,
      required String additionalinformation}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.savefeedback}?additionalInfo=$additionalinformation&taskTargetId=$taskTargetId'),
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

  //////////------------------//////////////////////
  Future<ApiResponse> submitReview({required String taskTargetId}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.submitreview}?taskTargetId=$taskTargetId'),
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

  void dispose() {
    client.close();
  }
}
