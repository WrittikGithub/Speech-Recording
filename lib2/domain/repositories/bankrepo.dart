import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/bankdetails_model.dart';
import 'package:sdcp_rebuild/data/postbank_details_model.dart';
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

class Bankrepo {
  final http.Client client;
  Bankrepo({http.Client? client}) : client = client ?? http.Client();
  Future<ApiResponse<BankdetailsModel>> fetchuserbankdetails() async {
    try {
      final token = await getUserToken();
      var response = await client.get(
        Uri.parse('${Endpoints.baseurl}${Endpoints.fetchbankdetails}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      final responseData = jsonDecode(response.body);
      //log(response.body);

      if (!responseData["error"] && responseData["status"] == 200) {
        final userbankDetails = BankdetailsModel.fromJson(responseData['data']);

        return ApiResponse(
          data: userbankDetails,
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

  Future<ApiResponse> postBankdetails(
      {required PostbankDetailsModel bankdetails}) async {
    try {
      final token = await getUserToken();
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.bankupdate}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(bankdetails),
      );

      final responseData = jsonDecode(response.body);
      log(response.body);
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
