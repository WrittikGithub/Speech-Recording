import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
      final apiResponse = await _fetchcreviewcontent(taskTargetId: taskTargetId);
      
      if (!apiResponse.error && apiResponse.data != null) {
        // Always delete old content to ensure clean data
        await reviewContentDatabaseHelper
            .deleteContentsByTargetTaskTargetId(taskTargetId);
        
        // Insert new content
        await reviewContentDatabaseHelper
            .insertReviewContents(apiResponse.data!);
        
        // Verify content was saved correctly
        final savedContents = await reviewContentDatabaseHelper
            .getContentsByTargetTaskTargetId(taskTargetId);
        
        if (savedContents.isEmpty) {
          throw Exception('Content failed to save properly');
        }
        
        // Force a delay long enough for database operations to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        print('Successfully updated ${savedContents.length} contents for task $taskTargetId');
      }
    } catch (e) {
      debugPrint('Content sync error for task $taskTargetId: ${e.toString()}');
      rethrow;
    }
  }

  // Method for single review content download
  Future<bool> downloadReviewContent(String taskTargetId) async {
    try {
      debugPrint('Starting download for review content: $taskTargetId');
      
      // Fetch review content from API using the fetch method that includes error handling
      final apiResponse = await fetchcreviewcontent(taskTargetId: taskTargetId);
      
      if (apiResponse.error || apiResponse.data == null || apiResponse.data!.isEmpty) {
        debugPrint('API error when fetching review content: ${apiResponse.message}');
        return false;
      }
      
      debugPrint('Successfully fetched ${apiResponse.data!.length} content items from API');
      
      // Clear existing content for this task
      await reviewContentDatabaseHelper.deleteContentsByTargetTaskTargetId(taskTargetId);
      
      // Insert new content
      await reviewContentDatabaseHelper.insertReviewContents(apiResponse.data!);
      
      // Update the review in the reviews table to include the audio path
      final contents = await reviewContentDatabaseHelper.getContentsByTargetTaskTargetId(taskTargetId);
      debugPrint('Retrieved ${contents.length} content items after insertion');
      
      // Get the review model to update
      final reviews = await reviewsDatabaseHelper.getAllReviews();
      final matchingReviews = reviews.where((r) => r.taskTargetId == taskTargetId).toList();
      
      if (matchingReviews.isEmpty) {
        debugPrint('No matching review found in database with taskTargetId: $taskTargetId');
        return true; // Content downloaded but review not found
      }
      
      final reviewToUpdate = matchingReviews.first;
      
      // Check if any content has a target path for audio
      final audioContents = contents.where((c) => 
        c.targetTargetContentPath.isNotEmpty).toList();
      
      debugPrint('Found ${audioContents.length} content items with audio paths');
      
      if (audioContents.isNotEmpty) {
        // Use the first content with audio
        var audioPath = audioContents.first.targetTargetContentPath;
        debugPrint('Original audio path: $audioPath');
        
        // Ensure the path doesn't have 'file://' prefix which can cause issues
        if (audioPath.startsWith('file://')) {
          audioPath = audioPath.substring(7);
          debugPrint('Corrected audio path: $audioPath');
        }
        
        // Check if file exists
        final audioFile = File(audioPath);
        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();
          debugPrint('Audio file exists with size: $fileSize bytes');
        } else {
          debugPrint('WARNING: Audio file does not exist at path: $audioPath');
        }
        
        // Create updated review model with targetContentPath
        final updatedReview = ReviewsModel(
          taskId: reviewToUpdate.taskId,
          taskTargetId: reviewToUpdate.taskTargetId,
          projectId: reviewToUpdate.projectId,
          languageName: reviewToUpdate.languageName,
          taskPrefix: reviewToUpdate.taskPrefix,
          taskTitle: reviewToUpdate.taskTitle,
          taskType: reviewToUpdate.taskType,
          status: reviewToUpdate.status,
          createdDate: reviewToUpdate.createdDate,
          assignedTo: reviewToUpdate.assignedTo,
          project: reviewToUpdate.project,
          contents: reviewToUpdate.contents,
          targetContentPath: audioPath,
        );
        
        // Update the review in the database
        await reviewsDatabaseHelper.updateReview(updatedReview);
        debugPrint('Updated review with audio path: $audioPath');
      } else {
        debugPrint('No audio content found for task: $taskTargetId');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error downloading review content: ${e.toString()}');
      // Do not rethrow, just return false
      return false;
    }
  }

  Future<ApiResponse<List<ReviewContentModel>>> _fetchcreviewcontent({
    required String taskTargetId,
  }) async {
    try {
      debugPrint('Fetching review content for task: $taskTargetId');
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.reviewcontents}?taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('API response status code: ${response.statusCode}');
      debugPrint('API response body (preview): ${response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body}');

      try {
        final responseData = jsonDecode(response.body);
        
        if (!responseData["error"] && responseData["status"] == 200) {
          // Parse the nested JSON data - make sure all keys exist
          if (responseData.containsKey('data') && 
              responseData['data'] is Map && 
              responseData['data'].containsKey('contents') &&
              responseData['data']['contents'] is List) {
            
            final List<dynamic> jsonList = responseData['data']['contents'];
            debugPrint('Retrieved ${jsonList.length} content items from API');
            
            final List<ReviewContentModel> reviewcontentlist =
                jsonList.map((json) => ReviewContentModel.fromJson(json)).toList();

            return ApiResponse(
              data: reviewcontentlist,
              message: responseData['message'] ?? 'Success',
              error: false,
              status: responseData["status"],
            );
          } else {
            debugPrint('API response format error: Missing expected keys in response structure');
            return ApiResponse(
              data: null,
              message: 'Invalid API response format',
              error: true,
              status: 400,
            );
          }
        } else {
          debugPrint('API returned error: ${responseData['message'] ?? 'Unknown error'}');
          return ApiResponse(
            data: null,
            message: responseData['message'] ?? 'Something went wrong',
            error: true,
            status: responseData["status"] ?? 400,
          );
        }
      } catch (e) {
        debugPrint('Error parsing API response: $e');
        return ApiResponse(
          data: null,
          message: 'Invalid response format from server',
          error: true,
          status: 400,
        );
      }
    } catch (e) {
      debugPrint('Network error in _fetchcreviewcontent: $e');
      log(e.toString());
      return ApiResponse(
        data: null,
        message: 'Network or server error: ${e.toString()}',
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
