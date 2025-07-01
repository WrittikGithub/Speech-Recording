import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

import 'package:sdcp_rebuild/domain/repositories/loginrepo.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final Loginrepo repository;
  
  // GoogleSignIn with serverClientId (ensure this matches your web client ID in Google Cloud Console)
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Ensure this is your WEB client ID for token verification on backend if needed,
    // but for direct Android sign-in, clientId parameter in GoogleSignIn() is preferred if you have one for Android.
    // The current PHP backend uses this serverClientId to verify the token.
    serverClientId: '93186379991-qqeoh8r1obcq3nuvk86q9hppl3vshv51.apps.googleusercontent.com',
  );

  LoginBloc({required this.repository}) : super(LoginInitial()) {
    on<LoginButtonClickingEvent>(loginevent);
    on<GoogleSignInEvent>(_onGoogleSignInEvent);
    on<AppleSignInEvent>(appleSignInEvent);
    on<GoogleSignOutEvent>(_onGoogleSignOutEvent);
    on<CompleteGoogleRegistrationEvent>(_onCompleteGoogleRegistrationEvent);
    on<CompleteAppleRegistrationEvent>(_onCompleteAppleRegistrationEvent);
  }

  @override
  void onTransition(Transition<LoginEvent, LoginState> transition) {
    super.onTransition(transition);
    print('[LoginBloc onTransition] $transition');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('[LoginBloc onError] $error, $stackTrace');
    super.onError(error, stackTrace);
  }

  FutureOr<void> loginevent(
      LoginButtonClickingEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());
    
    try {
      final response = await repository.userlogin(
          username: event.username, password: event.password);
      
      if (!response.error && response.status == 200) {
        final user = response.data;
        if (user != null) {
          print('Login successful for user ${user.userName}');
          print('signup_app value: ${user.signupApp}');
          
          // Save signup_app value to SharedPreferences again just to be sure
          final prefs = await SharedPreferences.getInstance();
          print('[LoginBloc] Saved SIGNUP_APP: ${user.signupApp}');
          await prefs.setString('SIGNUP_APP', user.signupApp);
          
          if (user.signupApp == '1') {
            print('Emitting LoginSuccessAppOneState');
            emit(LoginSuccessAppOneState());
          } else {
            print('Emitting LoginSuccessState');
            emit(LoginSuccessState());
          }
        } else {
          emit(LoginErrorState(message: 'User data is null'));
        }
      } else {
        emit(LoginErrorState(message: response.message));
      }
    } catch (e) {
      print('Error in login: $e');
      emit(LoginErrorState(message: 'An error occurred. Please try again.'));
    }
  }

  FutureOr<void> _onGoogleSignInEvent(
      GoogleSignInEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());
    try {
      await googleSignIn.signOut(); // Ensure clean state for choosing account
      // await googleSignIn.disconnect(); // Temporarily comment out to avoid PlatformException if called when not connected
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        print('[LoginBloc] Google Sign In successful on Flutter: ${googleUser.displayName}');
        print('[LoginBloc] Email: ${googleUser.email}');
        
        if (googleAuth.idToken == null) {
          emit(LoginErrorState(message: 'Failed to get ID token from Google.'));
          return;
        }
        
        final backendResponse = await repository.socialLoginWithGoogle(
          idToken: googleAuth.idToken!,
          email: googleUser.email,
          displayName: googleUser.displayName ?? googleUser.email.split('@').first,
          googleUserId: googleUser.id
        );
        
        if (!backendResponse.error && 
            backendResponse.status == 202 && 
            backendResponse.additionalData != null && 
            backendResponse.additionalData!['needsAdditionalInfo'] == true) {
          final additionalInfo = backendResponse.additionalData!;
          print('[LoginBloc] Google Sign-In needs additional info: $additionalInfo');
          emit(GoogleSignInNeedsMoreInfoState(
            googleUserId: additionalInfo['googleUserId']?.toString() ?? googleUser.id, 
            email: additionalInfo['email']?.toString() ?? googleUser.email,
            displayName: additionalInfo['displayName']?.toString() ?? googleUser.displayName ?? googleUser.email.split('@').first,
            existingUserId: additionalInfo['userId']?.toString(),
          ));
        } else if (!backendResponse.error && backendResponse.status == 200 && backendResponse.data != null) {
          final user = backendResponse.data!;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('USER_TOKEN', user.token);
          await prefs.setString('USER_ID', user.id);
          await prefs.setString('SIGNUP_APP', user.signupApp);
          print('[LoginBloc] Google Sign-In: Saved USER_TOKEN, USER_ID: ${user.id}, SIGNUP_APP: ${user.signupApp}');

          if (user.signupApp == '1') {
             emit(LoginSuccessAppOneState());
          } else {
             emit(LoginSuccessState());
          }
        } else {
          emit(LoginErrorState(message: backendResponse.message));
        }
      } else {
        emit(LoginErrorState(message: 'Google sign-in cancelled by user.'));
      }
    } catch (e) {
      print('[LoginBloc] Google sign-in BLoC error: $e');
      if (e is PlatformException) {
        if (e.code == 'sign_in_failed' || e.code == '10') {
          emit(LoginErrorState(message: 'Google sign-in failed. Details: ${e.message} (Code: ${e.code})'));
        } else if (e.code == 'network_error') {
           emit(LoginErrorState(message: 'Network error during Google sign-in.'));
        } else {
           emit(LoginErrorState(message: 'Google sign-in platform error: ${e.code} - ${e.message}'));
        }
      } else {
         emit(LoginErrorState(message: 'Google sign-in failed: An unexpected error occurred. ${e.toString()}'));
      }
    }
  }

  FutureOr<void> _onCompleteGoogleRegistrationEvent(
      CompleteGoogleRegistrationEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());
    try {
      final response = await repository.completeGoogleRegistration(
        googleUserId: event.googleUserId,
        email: event.email,
        displayName: event.displayName,
        mobileNumber: event.mobileNumber,
        countryCode: event.countryCode,
        motherTongueId: event.motherTongueId,
      );

      if (!response.error && response.data != null) {
        final user = response.data!;
        
        // Explicitly save all necessary user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('USER_TOKEN', user.token);
        await prefs.setString('USER_ID', user.id);
        await prefs.setString('SIGNUP_APP', user.signupApp);
        
        print('[LoginBloc] Google Registration Complete: USER_ID: ${user.id}, SIGNUP_APP: ${user.signupApp}');
        print('[LoginBloc] Saved to SharedPreferences - SIGNUP_APP: ${user.signupApp}');
        
        if (user.signupApp == '1') {
          print('[LoginBloc] Emitting LoginSuccessAppOneState for audio dashboard');
          emit(LoginSuccessAppOneState());
        } else {
          print('[LoginBloc] Emitting LoginSuccessState for regular dashboard');
          emit(LoginSuccessState());
        }
      } else {
        emit(LoginErrorState(message: response.message));
      }
    } catch (e) {
      print('[LoginBloc] Error during complete Google registration: $e');
      emit(LoginErrorState(message: 'Failed to complete registration: ${e.toString()}'));
    }
  }

  FutureOr<void> appleSignInEvent(
      AppleSignInEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());
    
    try {
      // Check if Apple Sign In is available on this device
      final isAvailable = await SignInWithApple.isAvailable();
      print('[LoginBloc] Apple Sign-In available: $isAvailable');
      
      if (!isAvailable) {
        emit(LoginErrorState(message: 'Sign in with Apple is not available on this device'));
        return;
      }
      
      print('[LoginBloc] Attempting Apple Sign-In with standard configuration');
      
      // Use a simple, standard approach that's known to work reliably
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // Use the package name as the client ID
          clientId: 'com.langlex.speech',
          // Use the standard redirect URI from the example
          redirectUri: Uri.parse(
            'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple',
          ),
        ),
      );
      
      print('[LoginBloc] Apple Sign-In successful!');
      print('[LoginBloc] User ID: ${credential.userIdentifier}');
      print('[LoginBloc] Email: ${credential.email}');
      print('[LoginBloc] Name: ${credential.givenName} ${credential.familyName}');
      
      // Extract user information
      final identityToken = credential.identityToken;
      final authCode = credential.authorizationCode;
      final firstName = credential.givenName ?? '';
      final lastName = credential.familyName ?? '';
      final email = credential.email ?? '';
      final fullName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
      final appleUserId = credential.userIdentifier ?? '';
      
      if (identityToken == null) {
        emit(LoginErrorState(message: 'Failed to get identity token from Apple'));
        return;
      }
      
      // Apple may not return email on subsequent sign-ins
      if (email.isEmpty) {
        // Emit state that requires the user to provide an email
        emit(AppleSignInNeedsMoreInfoState(
          appleUserId: appleUserId,
          email: '',
          displayName: fullName.isNotEmpty ? fullName : 'Apple User',
        ));
        return;
      }
      
      // For testing purposes, just emit a successful state
      emit(AppleSignInSuccessState());
      
      // In production, you would make a backend call here to validate the credentials
      /*
      // Call backend API to verify and log in the user
      final backendResponse = await repository.socialLoginWithApple(
        idToken: identityToken,
        authCode: authCode,
        email: email,
        displayName: fullName.isNotEmpty ? fullName : 'Apple User',
        appleUserId: appleUserId,
      );
      
      if (!backendResponse.error && backendResponse.status == 200 && backendResponse.data != null) {
        final user = backendResponse.data!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('USER_TOKEN', user.token);
        await prefs.setString('USER_ID', user.id);
        await prefs.setString('SIGNUP_APP', user.signupApp);
        print('[LoginBloc] Apple Sign-In: Saved USER_TOKEN, USER_ID: ${user.id}, SIGNUP_APP: ${user.signupApp}');

        if (user.signupApp == '1') {
          emit(LoginSuccessAppOneState());
        } else {
          emit(LoginSuccessState());
        }
      } else if (!backendResponse.error && 
                backendResponse.status == 202 && 
                backendResponse.additionalData != null && 
                backendResponse.additionalData!['needsAdditionalInfo'] == true) {
        // Handle case where user needs to provide additional information
        final additionalInfo = backendResponse.additionalData!;
        emit(AppleSignInNeedsMoreInfoState(
          appleUserId: additionalInfo['appleUserId']?.toString() ?? appleUserId,
          email: additionalInfo['email']?.toString() ?? email,
          displayName: additionalInfo['displayName']?.toString() ?? fullName,
        ));
      } else {
        emit(LoginErrorState(message: backendResponse.message));
      }
      */
    } catch (e) {
      print('Apple sign-in error: $e');
      emit(LoginErrorState(message: 'Apple sign-in failed: ${e.toString()}'));
    }
  }

  // Utility function to generate a random nonce for Apple Sign In
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Utility function to convert string to SHA256 hash
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Handler for GoogleSignOutEvent
  FutureOr<void> _onGoogleSignOutEvent(
      GoogleSignOutEvent event, Emitter<LoginState> emit) async {
    try {
      await googleSignIn.signOut(); 
      await googleSignIn.disconnect(); 
      await repository.clearSharedPrefs(); // Clear SharedPreferences
      print('[LoginBloc] Google Sign-Out, Disconnect, and Prefs Cleared successful');
      emit(LoggedOutState()); 
    } catch (e) {
      print('[LoginBloc] Error during Google Sign-Out/Disconnect: $e');
      // Even if sign-out fails, attempt to clear prefs and emit LoggedOutState
      try {
        await repository.clearSharedPrefs();
      } catch (prefsError) {
        print('[LoginBloc] Error clearing prefs during sign-out error: $prefsError');
      }
      emit(LoggedOutState()); // Or a specific error state for logout failure
    }
  }

  FutureOr<void> _onCompleteAppleRegistrationEvent(
      CompleteAppleRegistrationEvent event, Emitter<LoginState> emit) async {
    
    try {
      final response = await repository.completeAppleRegistration(
        appleUserId: event.appleUserId,
        email: event.email,
        displayName: event.displayName,
        mobileNumber: event.mobileNumber,
        countryCode: event.countryCode,
        motherTongueId: event.motherTongueId,
      );

      if (!response.error && response.data != null) {
        final user = response.data!;
        
        // Explicitly save all necessary user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('USER_TOKEN', user.token);
        await prefs.setString('USER_ID', user.id);
        await prefs.setString('SIGNUP_APP', user.signupApp);
        
        print('[LoginBloc] Apple Registration Complete: USER_ID: ${user.id}, SIGNUP_APP: ${user.signupApp}');
        print('[LoginBloc] Saved to SharedPreferences - SIGNUP_APP: ${user.signupApp}');
        
        if (user.signupApp == '1') {
          print('[LoginBloc] Emitting LoginSuccessAppOneState for audio dashboard');
          emit(LoginSuccessAppOneState());
        } else {
          print('[LoginBloc] Emitting LoginSuccessState for regular dashboard');
          emit(LoginSuccessState());
        }
      } else {
        emit(LoginErrorState(message: response.message));
      }
    } catch (e) {
      print('[LoginBloc] Error during complete Apple registration: $e');
      emit(LoginErrorState(message: 'Failed to complete registration: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
