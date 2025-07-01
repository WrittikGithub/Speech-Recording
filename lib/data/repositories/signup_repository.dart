import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sdcp_rebuild/core/endpoints.dart';
import 'package:sdcp_rebuild/data/models/api_response.dart';
import 'package:sdcp_rebuild/data/models/language_model.dart';
import 'package:sdcp_rebuild/data/models/country_model.dart';

class SignupRepository {
  final http.Client client;
  SignupRepository({http.Client? client}) : client = client ?? http.Client();

  Future<ApiResponse> signup({
    required String userFullName,
    required String userEmailAddress,
    required String userName,
    required String userPassword,
    required String passwordConfirmation,
    required String country,
    required String userContact,
    required String mtongue,
    required String authRememberCheck,
  }) async {
    try {
      final url = Uri.parse('${Endpoints.baseurl}${Endpoints.signup}');
      
      print('Sending signup request to: $url');
      print('Request parameters:');
      print('userFullName: $userFullName');
      print('userEmailAddress: $userEmailAddress');
      print('userName: $userName');
      print('country: $country');
      print('mtongue: $mtongue');
      
      final response = await http.post(
        url,
        body: {
          'userFullName': userFullName,
          'userEmailAddress': userEmailAddress,
          'userName': userName,
          'userPassword': userPassword,
          'password_confirmation': passwordConfirmation,
          'country': country,
          'userContact': userContact,
          'mtongue': mtongue,
          'auth_remember_check': authRememberCheck,
        },
      );
      
      print('Signup response status: ${response.statusCode}');
      print('Raw response body: ${response.body}');
      
      // Fix for the "Sent!" prefix in the response
      String responseBodyFixed = response.body;
      if (responseBodyFixed.startsWith('Sent!')) {
        responseBodyFixed = responseBodyFixed.substring(5); // Remove the "Sent!" prefix
      }
      
      print('Fixed response body: $responseBodyFixed');
      
      final responseData = jsonDecode(responseBodyFixed);
      print('Parsed response data: $responseData');
      
      // Check for success based on the error flag in the response
      final bool isError = responseData['error'] ?? false;
      final String message = responseData['message'] ?? 'Signup operation completed';
      
      print('Is error from API: $isError');
      print('Message from API: $message');
      
      return ApiResponse(
        error: isError,
        message: message,
        data: responseData['data'],
      );
    } catch (e) {
      print('Exception in signup repository: ${e.toString()}');
      return ApiResponse(
        error: true,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<Language>>> getLanguages() async {
    try {
      final url = Uri.parse('${Endpoints.baseurl}${Endpoints.getLanguages}');
      
      print('Fetching languages from: $url');
      final response = await client.get(url);
      print('Language response status: ${response.statusCode}');
      
      final responseData = jsonDecode(response.body);
      
      // Check if the API returned success (even though HTTP status might be 201)
      if (responseData['error'] == false) {
        final List<dynamic> languagesJson = responseData['data'];
        final List<Language> languages = [];
        
        for (var json in languagesJson) {
          try {
            languages.add(Language.fromJson(json));
          } catch (e) {
            print('Error parsing language: $e');
          }
        }
        
        return ApiResponse<List<Language>>(
          error: false,
          message: responseData['message'] ?? 'Languages loaded successfully',
          data: languages,
        );
      } else {
        return ApiResponse<List<Language>>(
          error: true,
          message: responseData['message'] ?? 'Failed to load languages',
          data: null,
        );
      }
    } catch (e) {
      print('Exception in getLanguages: $e');
      return ApiResponse<List<Language>>(
        error: true,
        message: 'An error occurred: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse<List<Country>>> getCountries() async {
    try {
      final url = Uri.parse('${Endpoints.baseurl}${Endpoints.getCountries}');
      
      print('Fetching countries from: $url');
      final response = await client.get(url);
      print('Country response status: ${response.statusCode}');
      
      final responseData = jsonDecode(response.body);
      
      // Check if the API returned success (even though HTTP status might be 201)
      if (responseData['error'] == false) {
        final List<dynamic> countriesJson = responseData['data'];
        final List<Country> countries = [];
        
        for (var json in countriesJson) {
          try {
            countries.add(Country.fromJson(json));
          } catch (e) {
            print('Error parsing country: $e');
          }
        }
        
        return ApiResponse<List<Country>>(
          error: false,
          message: responseData['message'] ?? 'Countries loaded successfully',
          data: countries,
        );
      } else {
        return ApiResponse<List<Country>>(
          error: true,
          message: responseData['message'] ?? 'Failed to load countries',
          data: null,
        );
      }
    } catch (e) {
      print('Exception in getCountries: $e');
      return ApiResponse<List<Country>>(
        error: true,
        message: 'An error occurred: ${e.toString()}',
        data: null,
      );
    }
  }

  Future<ApiResponse> verifyEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Endpoints.baseurl}${Endpoints.verifyEmail}'),
        body: {
          'email': email,
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          error: false,
          message: responseData['message'] ?? 'Email verification successful',
          data: responseData['data'],
        );
      } else {
        return ApiResponse(
          error: true,
          message: responseData['message'] ?? 'Failed to verify email',
        );
      }
    } catch (e) {
      return ApiResponse(
        error: true,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  void dispose() {
    client.close();
  }
} 