import 'dart:async';
import 'dart:convert';
import 'dart:developer';
// Ensure SocketException is available

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/models/user_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse<T> {
  final T? data;
  final String message;
  final bool error;
  final int status;
  final Map<String, dynamic>? additionalData; // Field for extra data like needsAdditionalInfo

  ApiResponse({
    this.data,
    required this.message,
    required this.error,
    required this.status,
    this.additionalData, // Initialize
  });
}

class Loginrepo {
  final http.Client client;
  Loginrepo({http.Client? client}) : client = client ?? http.Client();
  
  Future<ApiResponse<User>> userlogin({
    required String username, 
    required String password
  }) async {
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
        // Parse the user data including signup_app field
        print('[Loginrepo - userlogin] responseData["data"] before User.fromJson: ${responseData["data"]}');
        final userData = User.fromJson(responseData["data"]);
        
        // Store user data in SharedPreferences
        SharedPreferences preferences = await SharedPreferences.getInstance();
        print('[LoginRepo] Saving SIGNUP_APP: ${userData.signupApp}');
        preferences.setString('USER_TOKEN', userData.token);
        preferences.setString('USER_ID', userData.id);
        preferences.setString('SIGNUP_APP', userData.signupApp);
        
        return ApiResponse(
          data: userData,
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
      log("Login Error: $e");
      return ApiResponse(
        data: null,
        message: 'Network or server error occurred during login.',
        error: true,
        status: 500,
      );
    }
  }

  Future<String> getSignupApp() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString('SIGNUP_APP') ?? '0';
  }

  Future<ApiResponse> socialLogin({
    required String email,
    required String name,
    required String socialId,
    required String loginType,
    required String token,
  }) async {
    try {
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}/social/login'), // Replace with your actual endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'socialId': socialId,
          'loginType': loginType,
          'token': token,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"]) {
        // Handle successful login
        return ApiResponse(
          data: User.fromJson(responseData["data"]), // Assuming you have a User model
          message: responseData['message'] ?? 'Login successful',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Login failed',
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

  Future<ApiResponse> socialSignup({
    required String email,
    required String name,
    required String socialId,
    required String loginType,
    required String token,
  }) async {
    try {
      var response = await client.post(
        Uri.parse('${Endpoints.baseurl}/social/signup'), // Replace with your actual endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'socialId': socialId,
          'loginType': loginType,
          'token': token,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (!responseData["error"]) {
        // Handle successful signup
        return ApiResponse(
          data: User.fromJson(responseData["data"]), // Assuming you have a User model
          message: responseData['message'] ?? 'Signup successful',
          error: false,
          status: responseData["status"],
        );
      } else {
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Signup failed',
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

  Future<ApiResponse<User>> socialLoginWithGoogle({
    required String idToken,
    required String email,
    required String displayName,
    required String googleUserId,
  }) async {
    try {
      final url = Uri.parse('${Endpoints.recordURL}api/social_login'); // Matches your backend route
      final requestBodyMap = {
        'idToken': idToken,
        'loginType': 'google',
        // Backend should derive email, displayName, googleUserId from idToken if possible,
        // but sending them can be a fallback or for direct use if backend logic expects them.
        'email': email, 
        'displayName': displayName,
        'googleUserId': googleUserId,
      };
      final requestBody = jsonEncode(requestBodyMap);
      print('[LoginRepo] Calling socialLoginWithGoogle URL: $url');
      print('[LoginRepo] Request body: $requestBody');

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('[LoginRepo] socialLoginWithGoogle - Response status code: ${response.statusCode}');
      print('[LoginRepo] socialLoginWithGoogle - Response body raw: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Log all relevant parts of responseData for clearer debugging
      print('[LoginRepo] socialLoginWithGoogle - Parsed responseData: $responseData');
      bool needsInfoCondition = responseData["error"] == false && 
                                responseData["data"] != null && 
                                responseData["data"] is Map && // Ensure data is a Map
                                responseData["data"]["needsAdditionalInfo"] == true &&
                                responseData["status"] == 202;
      print('[LoginRepo] socialLoginWithGoogle - Calculated needsInfoCondition: $needsInfoCondition');
      print('[LoginRepo]   - responseData["error"] == false: ${responseData["error"] == false}');
      print('[LoginRepo]   - responseData["data"] != null: ${responseData["data"] != null}');
      if (responseData["data"] != null && responseData["data"] is Map) {
        print('[LoginRepo]   - responseData["data"]["needsAdditionalInfo"] == true: ${responseData["data"]["needsAdditionalInfo"] == true}');
      } else {
        print('[LoginRepo]   - responseData["data"] is not a Map or is null, cannot check needsAdditionalInfo');
      }
      print('[LoginRepo]   - responseData["status"] == 202: ${responseData["status"] == 202}');


      // Check for the "needsAdditionalInfo" scenario (status 202 from backend's JSON)
      if (needsInfoCondition) {
        print('[LoginRepo] socialLoginWithGoogle - Path: Needs additional info');
        return ApiResponse(
          data: null, // No complete User object yet
          message: responseData['message'] ?? 'Additional information required.',
          error: false,
          status: 202, // Explicitly use 202
          additionalData: responseData["data"] as Map<String, dynamic>, // Pass the whole data map
        );
      } else if (responseData["error"] == false && responseData["status"] == 200 && responseData["data"] != null) {
        // Normal login success
        print('[LoginRepo] socialLoginWithGoogle - Path: Normal login success');
        print('[LoginRepo - socialLoginWithGoogle] responseData["data"] before User.fromJson: ${responseData["data"]}');
        final userData = User.fromJson(responseData["data"]);
        
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('USER_TOKEN', userData.token);
        preferences.setString('USER_ID', userData.id);
        preferences.setString('SIGNUP_APP', userData.signupApp);
        
        print('[LoginRepo] Social login successful for ${userData.userEmailAddress}');
        return ApiResponse(
          data: userData,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        // Other errors or unexpected backend responses
        print('[LoginRepo] socialLoginWithGoogle - Path: Other errors or unexpected response');
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Google login failed.',
          error: true,
          status: responseData["status"] ?? response.statusCode,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      log("Social Login Error: $e");
      return ApiResponse(
        data: null,
        message: 'Network or server error during Google login: ${e.toString()}',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<User>> socialLoginWithApple({
    required String idToken,
    required String authCode,
    required String email,
    required String displayName,
    required String appleUserId,
  }) async {
    try {
      final url = Uri.parse('${Endpoints.recordURL}api/social_login'); // Same endpoint as Google, but with different loginType
      final requestBodyMap = {
        'idToken': idToken,
        'authCode': authCode,
        'loginType': 'apple',
        'email': email, 
        'displayName': displayName,
        'appleUserId': appleUserId,
      };
      final requestBody = jsonEncode(requestBodyMap);
      print('[LoginRepo] Calling socialLoginWithApple URL: $url');
      print('[LoginRepo] Request body: $requestBody');

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('[LoginRepo] socialLoginWithApple - Response status code: ${response.statusCode}');
      print('[LoginRepo] socialLoginWithApple - Response body raw: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Log all relevant parts of responseData for clearer debugging
      print('[LoginRepo] socialLoginWithApple - Parsed responseData: $responseData');
      bool needsInfoCondition = responseData["error"] == false && 
                                responseData["data"] != null && 
                                responseData["data"] is Map && 
                                responseData["data"]["needsAdditionalInfo"] == true &&
                                responseData["status"] == 202;
      
      // Check for the "needsAdditionalInfo" scenario (status 202 from backend's JSON)
      if (needsInfoCondition) {
        print('[LoginRepo] socialLoginWithApple - Path: Needs additional info');
        return ApiResponse(
          data: null, // No complete User object yet
          message: responseData['message'] ?? 'Additional information required.',
          error: false,
          status: 202, // Explicitly use 202
          additionalData: responseData["data"] as Map<String, dynamic>, // Pass the whole data map
        );
      } else if (responseData["error"] == false && responseData["status"] == 200 && responseData["data"] != null) {
        // Normal login success
        print('[LoginRepo] socialLoginWithApple - Path: Normal login success');
        print('[LoginRepo - socialLoginWithApple] responseData["data"] before User.fromJson: ${responseData["data"]}');
        final userData = User.fromJson(responseData["data"]);
        
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setString('USER_TOKEN', userData.token);
        preferences.setString('USER_ID', userData.id);
        preferences.setString('SIGNUP_APP', userData.signupApp);
        
        print('[LoginRepo] Apple login successful for ${userData.userEmailAddress}');
        return ApiResponse(
          data: userData,
          message: responseData['message'] ?? 'Success',
          error: false,
          status: responseData["status"],
        );
      } else {
        // Other errors or unexpected backend responses
        print('[LoginRepo] socialLoginWithApple - Path: Other errors or unexpected response');
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Apple login failed.',
          error: true,
          status: responseData["status"] ?? response.statusCode,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      log("Apple Login Error: $e");
      return ApiResponse(
        data: null,
        message: 'Network or server error during Apple login: ${e.toString()}',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<User>> completeGoogleRegistration({
    required String googleUserId,
    required String email,
    required String displayName,
    required String mobileNumber,
    required String countryCode, // e.g., "+91"
    required String motherTongueId,
  }) async {
    try {
      final url = Uri.parse('${Endpoints.baseurl}/complete_registration');

      final requestBodyMap = {
        'googleUserId': googleUserId,
        'email': email,
        'displayName': displayName,
        'mobileNumber': mobileNumber,
        'countryCode': countryCode,
        'motherTongueId': motherTongueId,
      };
      final requestBody = jsonEncode(requestBodyMap);

      print('[LoginRepo] Calling completeGoogleRegistration URL: $url');
      print('[LoginRepo] Request body: $requestBody');

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('[LoginRepo] completeGoogleRegistration - Response status code: ${response.statusCode}');
      print('[LoginRepo] completeGoogleRegistration - Response body raw: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Accept both 200 and 201 as success from HTTP response,
      // and also check the 'error' and 'status' fields from the JSON payload.
      bool isSuccessHttpResponse = response.statusCode == 200 || response.statusCode == 201;
      bool isSuccessBackendLogic = responseData["error"] == false && 
                                   (responseData["status"] == 200 || responseData["status"] == 201);

      if (isSuccessHttpResponse && isSuccessBackendLogic && responseData["data"] != null) {
        print('[LoginRepo - completeGoogleRegistration] responseData["data"] before User.fromJson: ${responseData["data"]}');
        
        // Ensure 'user' object exists within 'data' from backend
        final Map<String, dynamic>? outerData = responseData["data"] as Map<String, dynamic>?;
        final Map<String, dynamic>? userDataMap = outerData?['user'] as Map<String, dynamic>?;
        final String? token = outerData?['token'] as String?;

        if (userDataMap != null && token != null) {
          // Add the token to the userDataMap if it's not already there,
          // or if your User.fromJson expects it at the top level of its input map.
          // Assuming User.fromJson can handle a map that includes user fields and the token.
          // If User.fromJson only expects user fields, you might need to construct it differently
          // and handle the token separately.
          // For now, let's assume User.fromJson can find 'token' if it's at the root of responseData["data"]
          // or if you merge it.
          // The backend response has token and user as siblings under 'data'.
          // So, we need to pass the correct map to User.fromJson and handle the token.
          
          // Let's create a map that User.fromJson can reliably use.
          // It seems your User.fromJson expects 'token' at the same level as other user fields.
          // The backend sends: "data": { "token": "...", "user": { ...user fields... } }
          // So, we need to combine these.
          Map<String, dynamic> combinedDataForUser = Map<String, dynamic>.from(userDataMap);
          combinedDataForUser['token'] = token; 
           // If User.fromJson needs other fields from outerData, add them here.
           // e.g. if signupApp was outside the 'user' object but inside 'data'.
           // Based on your log, signupApp is INSIDE the 'user' object from backend.
           // "user": { ..., "signup_app": "0", ... }
           // However, your User model might expect 'id' instead of 'userId', etc.
           // And it seems it also expects 'signupApp'. The log shows 'signup_app' not 'signupApp'.

          final userData = User.fromJson(combinedDataForUser);


          SharedPreferences preferences = await SharedPreferences.getInstance();
          // Use the token directly extracted, and user data from userData object
          await preferences.setString('USER_TOKEN', token); 
          await preferences.setString('USER_ID', userData.id); // Ensure userData.id is correct
          await preferences.setString('SIGNUP_APP', userData.signupApp);

          print('[LoginRepo] Google Registration Completion successful for ${userData.userEmailAddress}');
          return ApiResponse(
            data: userData,
            message: responseData['message'] ?? 'Success',
            error: false,
            status: responseData["status"] ?? response.statusCode, // Use status from response body or HTTP status
          );
        } else {
          print('[LoginRepo] completeGoogleRegistration - Error: "user" object or "token" is missing in response data["data"]');
          return ApiResponse(
            data: null,
            message: responseData['message'] ?? 'User data or token missing in response.',
            error: true,
            status: responseData["status"] ?? response.statusCode,
          );
        }
      } else {
        print('[LoginRepo] completeGoogleRegistration - Condition not met for success:');
        print('[LoginRepo]   isSuccessHttpResponse: $isSuccessHttpResponse (statusCode: ${response.statusCode})');
        print('[LoginRepo]   isSuccessBackendLogic: $isSuccessBackendLogic (json error: ${responseData["error"]}, json status: ${responseData["status"]})');
        print('[LoginRepo]   responseData["data"] != null: ${responseData["data"] != null}');
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Failed to complete registration.',
          error: true,
          status: responseData["status"] ?? response.statusCode,
        );
      }
    } catch (e) {
      print('[LoginRepo] Error in completeGoogleRegistration: $e');
      return ApiResponse(
        data: null,
        message: 'Network or server error during registration completion: ${e.toString()}',
        error: true,
        status: 500,
      );
    }
  }

  Future<ApiResponse<User>> completeAppleRegistration({
    required String appleUserId,
    required String email,
    required String displayName,
    required String mobileNumber,
    required String countryCode,
    required String motherTongueId,
  }) async {
    try {
      final url = Uri.parse('${Endpoints.baseurl}/complete_apple_registration');

      final requestBodyMap = {
        'appleUserId': appleUserId,
        'email': email,
        'displayName': displayName,
        'mobileNumber': mobileNumber,
        'countryCode': countryCode,
        'motherTongueId': motherTongueId,
      };
      final requestBody = jsonEncode(requestBodyMap);

      print('[LoginRepo] Calling completeAppleRegistration URL: $url');
      print('[LoginRepo] Request body: $requestBody');

      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('[LoginRepo] completeAppleRegistration - Response status code: ${response.statusCode}');
      print('[LoginRepo] completeAppleRegistration - Response body raw: ${response.body}');

      final responseData = jsonDecode(response.body);

      // Accept both 200 and 201 as success from HTTP response,
      // and also check the 'error' and 'status' fields from the JSON payload.
      bool isSuccessHttpResponse = response.statusCode == 200 || response.statusCode == 201;
      bool isSuccessBackendLogic = responseData["error"] == false && 
                                   (responseData["status"] == 200 || responseData["status"] == 201);

      if (isSuccessHttpResponse && isSuccessBackendLogic && responseData["data"] != null) {
        print('[LoginRepo] completeAppleRegistration - Path: Success response');
        
        final Map<String, dynamic> outerData = responseData["data"];
        
        // First, let's extract token from outerData if it exists
        final String token = outerData["token"] ?? '';
        
        if (outerData.containsKey("user") && outerData["user"] != null && token.isNotEmpty) {
          // If "user" is a nested object inside data, extract it
          final Map<String, dynamic> userDataMap = outerData["user"];
          
          // Now merge the two maps to create a combined user data map
          // This ensures we get both the user details AND the token
          final Map<String, dynamic> combinedDataForUser = Map.from(userDataMap);
          
          // Add token to the combined map
          combinedDataForUser['token'] = token; 

          final User user = User.fromJson(combinedDataForUser);

          SharedPreferences preferences = await SharedPreferences.getInstance();
          // Use the token directly extracted, and user data from userData object
          await preferences.setString('USER_TOKEN', token); 
          await preferences.setString('USER_ID', user.id);
          await preferences.setString('SIGNUP_APP', user.signupApp);

          print('[LoginRepo] Apple Registration Completion successful for ${user.userEmailAddress}');
          return ApiResponse(
            data: user,
            message: responseData['message'] ?? 'Success',
            error: false,
            status: responseData["status"] ?? response.statusCode,
          );
        } else {
          print('[LoginRepo] completeAppleRegistration - Error: "user" object or "token" is missing in response data["data"]');
          return ApiResponse(
            data: null,
            message: responseData['message'] ?? 'User data or token missing in response.',
            error: true,
            status: responseData["status"] ?? response.statusCode,
          );
        }
      } else {
        print('[LoginRepo] completeAppleRegistration - Condition not met for success:');
        print('[LoginRepo]   isSuccessHttpResponse: $isSuccessHttpResponse (statusCode: ${response.statusCode})');
        print('[LoginRepo]   isSuccessBackendLogic: $isSuccessBackendLogic (json error: ${responseData["error"]}, json status: ${responseData["status"]})');
        print('[LoginRepo]   responseData["data"] != null: ${responseData["data"] != null}');
        return ApiResponse(
          data: null,
          message: responseData['message'] ?? 'Failed to complete registration.',
          error: true,
          status: responseData["status"] ?? response.statusCode,
        );
      }
    } catch (e) {
      print('[LoginRepo] Error in completeAppleRegistration: $e');
      return ApiResponse(
        data: null,
        message: 'Network or server error during registration completion: ${e.toString()}',
        error: true,
        status: 500,
      );
    }
  }

  Future<void> clearSharedPrefs() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('USER_TOKEN');
    await preferences.remove('USER_ID');
    await preferences.remove('SIGNUP_APP');
    // Remove any other user-specific data
    print('[LoginRepo] Cleared user-specific SharedPreferences.');
  }

  void dispose() {
    client.close();
  }
}
