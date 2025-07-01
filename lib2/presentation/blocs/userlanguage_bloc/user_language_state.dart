part of 'user_language_bloc.dart';

@immutable
sealed class UserLanguageState {}

final class UserLanguageInitial extends UserLanguageState {}

final class UserLanguageLoadingState extends UserLanguageState {}

final class UserLanguageSuccessState extends UserLanguageState {
  final List<LanguageModel> userlangauges;

  UserLanguageSuccessState({required this.userlangauges});
}

final class UserLanguageErrorState extends UserLanguageState {
  final String message;

  UserLanguageErrorState({required this.message});
}
