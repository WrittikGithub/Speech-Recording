part of 'login_bloc.dart';

@immutable
abstract class LoginEvent {}

class LoginButtonClickingEvent extends LoginEvent {
  final String username;
  final String password;
  LoginButtonClickingEvent({required this.username, required this.password});
}

class GoogleSignInEvent extends LoginEvent {}

class AppleSignInEvent extends LoginEvent {}

class GoogleSignOutEvent extends LoginEvent {}

// New Event for completing registration
class CompleteGoogleRegistrationEvent extends LoginEvent {
  final String googleUserId;
  final String email;
  final String displayName;
  final String mobileNumber;
  final String countryCode;
  final String motherTongueId;

  CompleteGoogleRegistrationEvent({
    required this.googleUserId,
    required this.email,
    required this.displayName,
    required this.mobileNumber,
    required this.countryCode,
    required this.motherTongueId,
  });
}

class CompleteAppleRegistrationEvent extends LoginEvent {
  final String appleUserId;
  final String email;
  final String displayName;
  final String mobileNumber;
  final String countryCode;
  final String motherTongueId;

  CompleteAppleRegistrationEvent({
    required this.appleUserId,
    required this.email,
    required this.displayName,
    required this.mobileNumber,
    required this.countryCode,
    required this.motherTongueId,
  });
}
