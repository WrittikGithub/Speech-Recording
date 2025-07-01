import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/user_profile_model.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

class Profilerepo {
  final http.Client client;
  Profilerepo({http.Client? client}) : client = client ?? http.Client();
  Future<ApiResponse<UserProfileModel>> fetchuserprofile() async {
    try {
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.userprofile}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final responseData = jsonDecode(response.body);
      
      if (!responseData["error"] && responseData["status"] == 200) {
          final userData = responseData['data']['user']['userinfo'];
             SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('USER_NAME', userData['userName']);
         GlobalState().setUsername(userData['userName']);
        final userprofile = UserProfileModel.fromJson(userData);
       
        return ApiResponse(
          data: userprofile,
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
///-------------------////////////////////
   Future<ApiResponse> updateprofile(String userFullName, String userEmailAddress,String username) async {
    try {
      
       final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.updateprofile}?userFullName=$userFullName&userEmailAddress=$userEmailAddress&userName=$username'),
        headers: {
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
      
        return ApiResponse(
          data:null,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData["data"]["userName"] ?? 'Something went wrong',
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
