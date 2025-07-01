part of 'login_bloc.dart';

@immutable
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginSuccessState extends LoginState {}

class LoginSuccessAppOneState extends LoginState {}

class LoginErrorState extends LoginState {
  final String message;

  LoginErrorState({required this.message});
}

class GoogleSignInSuccessState extends LoginState {}

class AppleSignInSuccessState extends LoginState {}

class LoggedOutState extends LoginState {}

// New State for when Google Sign-In needs more info
class GoogleSignInNeedsMoreInfoState extends LoginState {
  final String googleUserId;
  final String email;
  final String displayName;
  final String? existingUserId; // Optional: if the user partially exists

  GoogleSignInNeedsMoreInfoState({
    required this.googleUserId,
    required this.email,
    required this.displayName,
    this.existingUserId,
  });
}

// New State for when Apple Sign-In needs more info
class AppleSignInNeedsMoreInfoState extends LoginState {
  final String appleUserId;
  final String email;
  final String displayName;
  final String? existingUserId; // Optional: if the user partially exists

  AppleSignInNeedsMoreInfoState({
    required this.appleUserId,
    required this.email,
    required this.displayName,
    this.existingUserId,
  });
}
