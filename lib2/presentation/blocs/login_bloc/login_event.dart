part of 'login_bloc.dart';

@immutable
sealed class LoginEvent {}

final class LoginButtonClickingEvent extends LoginEvent {
  final String username;
  final String password;

  LoginButtonClickingEvent({required this.username, required this.password});
}
