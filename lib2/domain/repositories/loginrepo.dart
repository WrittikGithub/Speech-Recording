import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';

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

class Loginrepo {
  final http.Client client;
  Loginrepo({http.Client? client}) : client = client ?? http.Client();
  Future<ApiResponse> userlogin(
      {required String username, required String password}) async {
   
    try {
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.login}'),
         headers: {
            'Content-Type': 'application/json',
          },
        body: jsonEncode({'userName': username, 'userPassword': password}),
      );
    
      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('USER_TOKEN', responseData["data"]["token"]);
        preferences.setString('USER_ID', responseData["data"]["userId"]);
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
