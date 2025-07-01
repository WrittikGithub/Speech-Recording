part of 'signup_bloc.dart';

@immutable
abstract class SignupEvent extends Equatable {
  const SignupEvent();
  
  @override
  List<Object> get props => [];
}

class SignupButtonClickEvent extends SignupEvent {
  final String userFullName;
  final String userEmailAddress;
  final String userName;
  final String userPassword;
  final String passwordConfirmation;
  final String country;
  final String userContact;
  final String mtongue;
  final String authRememberCheck;

  const SignupButtonClickEvent({
    required this.userFullName,
    required this.userEmailAddress,
    required this.userName,
    required this.userPassword,
    required this.passwordConfirmation,
    required this.country,
    required this.userContact,
    required this.mtongue,
    required this.authRememberCheck,
  });

  @override
  List<Object> get props => [
    userFullName,
    userEmailAddress,
    userName,
    userPassword,
    passwordConfirmation,
    country,
    userContact,
    mtongue,
    authRememberCheck,
  ];
}

class FetchCountriesEvent extends SignupEvent {}

class FetchLanguagesEvent extends SignupEvent {} 