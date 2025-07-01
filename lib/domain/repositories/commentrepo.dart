import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/comment_model.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';


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

class Commentrepo {
  final http.Client client;
  Commentrepo({http.Client? client}) : client = client ?? http.Client();

  Future<ApiResponse<List<CommentModel>>> fetchcomment(
      {required String taskTargetId, required String contentId}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.fetchcomment}?contentId=$contentId&taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      

      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<CommentModel> commentlist =
            jsonList.map((json) => CommentModel.fromJson(json)).toList();
        
        return ApiResponse(
          data: commentlist,
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
////////////------------------///////////////////
  Future<ApiResponse> savechcomment(
      {required String taskTargetId, required String contentId,required String comment}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.saveComment}?contentId=$contentId&taskTargetId=$taskTargetId&comment=$comment'),
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
  /////-------fetchreviewcomment-------////////
  Future<ApiResponse<List<CommentModel>>> fetchreviewcomment(
      {required String taskTargetId, required String contentId}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.reviewfetchcomment}?contentId=$contentId&taskTargetId=$taskTargetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      

      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<CommentModel> commentlist =
            jsonList.map((json) => CommentModel.fromJson(json)).toList();
        
        return ApiResponse(
          data: commentlist,
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
////////-------------savereviewcomment----------//////
  Future<ApiResponse> savereviewcomment(
      {required String taskTargetId, required String contentId,required String comment}) async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse(
            '${Endpoints.baseurl}${Endpoints.savereviewcomment}?contentId=$contentId&taskTargetId=$taskTargetId&comment=$comment'),
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
