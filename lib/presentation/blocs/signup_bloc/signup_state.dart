part of 'signup_bloc.dart';

@immutable
abstract class SignupState extends Equatable {
  const SignupState();
  
  @override
  List<Object> get props => [];
}

class SignupInitial extends SignupState {}

class SignupLoadingState extends SignupState {}

class SignupSuccessState extends SignupState {
  final String message;
  final dynamic data;

  const SignupSuccessState({required this.message, this.data});

  @override
  List<Object> get props => [message];
}

class SignupErrorState extends SignupState {
  final String message;

  const SignupErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

class DataLoadingState extends SignupState {}

class DataLoadingErrorState extends SignupState {
  final String message;
  
  const DataLoadingErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}

class CountriesLoadedState extends SignupState {
  final List<Country> countries;
  
  const CountriesLoadedState(this.countries);
  
  @override
  List<Object> get props => [countries];
}

class LanguagesLoadedState extends SignupState {
  final List<Language> languages;
  
  const LanguagesLoadedState(this.languages);
  
  @override
  List<Object> get props => [languages];
} 