import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/dashboard_datamodel.dart';
import 'package:sdcp_rebuild/data/dashbord_taskmodel.dart';
import 'package:sdcp_rebuild/data/notification_model.dart';
import 'package:sdcp_rebuild/data/reportmodel.dart';
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

class Dashbordrepo {
  final http.Client client;
  Dashbordrepo({http.Client? client}) : client = client ?? http.Client();
  Future<ApiResponse<DashboardDatamodel>> fetchdashborddata() async {
    try {
      
       final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.dashboard}'),
        headers: {
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final dashboardData = DashboardDatamodel.fromJson(responseData['data']);
        return ApiResponse(
          data: dashboardData,
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

//////-----------------dashboardtask-------------/////
  Future<ApiResponse<List<DashboardTaskModel>>> fetchdashbordtask() async {
    try {

      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.dashboardtasklist}'),
        headers: {
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data'];
        final List<DashboardTaskModel> dashbordTasks =
            jsonList.map((json) => DashboardTaskModel.fromJson(json)).toList();
        return ApiResponse(
          data:dashbordTasks,
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
///////----------notificationrepo------------/////////////////
  Future<ApiResponse<List<NotificationMOdel>>> fetchnotification() async {
    try {

      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.notification}'),
        headers: {
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final List<dynamic> jsonList = responseData['data']['notifications'];
        final List<NotificationMOdel> notificationlist =
            jsonList.map((json) => NotificationMOdel.fromJson(json)).toList();
        return ApiResponse(
          data:notificationlist,
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
  ///////--------------fetchreport----------///////
   Future<ApiResponse<Reportmodel>> fetchreport({required String fromDate,required String toDate}) async {
    try {
      
       final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.report}?fromDate=$fromDate&toDate=$toDate'),
        headers: {
          'Authorization': token,
        },
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"] && responseData["status"] == 200) {
        final reportData= Reportmodel.fromJson(responseData['data']);
        return ApiResponse(
          data:reportData,
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
