import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:sdcp_rebuild/data/repositories/signup_repository.dart';
import 'package:sdcp_rebuild/data/models/country_model.dart';
import 'package:sdcp_rebuild/data/models/language_model.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupRepository repository;
  List<Country> countries = [];
  List<Language> languages = [];

  SignupBloc({required this.repository}) : super(SignupInitial()) {
    on<SignupButtonClickEvent>(_onSignupButtonClick);
    on<FetchCountriesEvent>(_onFetchCountries);
    on<FetchLanguagesEvent>(_onFetchLanguages);
  }

  Future<void> _onSignupButtonClick(
    SignupButtonClickEvent event,
    Emitter<SignupState> emit,
  ) async {
    emit(SignupLoadingState());

    try {
      print('Starting signup process...');
      print('Signup params: ${event.userFullName}, ${event.userEmailAddress}, country: ${event.country}, mtongue: ${event.mtongue}');
      
      final response = await repository.signup(
        userFullName: event.userFullName,
        userEmailAddress: event.userEmailAddress,
        userName: event.userName,
        userPassword: event.userPassword,
        passwordConfirmation: event.passwordConfirmation,
        country: event.country,
        userContact: event.userContact,
        mtongue: event.mtongue,
        authRememberCheck: event.authRememberCheck,
      );

      print('Signup response received:');
      print('Error flag: ${response.error}');
      print('Message: ${response.message}');
      print('Data: ${response.data}');

      if (!response.error) {
        print('Emitting SignupSuccessState');
        emit(SignupSuccessState(
          message: response.message,
          data: response.data,
        ));
      } else {
        print('Emitting SignupErrorState');
        emit(SignupErrorState(message: response.message));
      }
    } catch (e) {
      print('Exception during signup: ${e.toString()}');
      emit(SignupErrorState(message: 'An error occurred: ${e.toString()}'));
    }
  }
  
  Future<void> _onFetchCountries(
    FetchCountriesEvent event,
    Emitter<SignupState> emit,
  ) async {
    emit(DataLoadingState());
    
    try {
      final response = await repository.getCountries();
      
      if (!response.error) {
        countries = response.data ?? [];
        emit(CountriesLoadedState(countries));
      } else {
        emit(DataLoadingErrorState(response.message));
      }
    } catch (e) {
      emit(DataLoadingErrorState('Failed to load countries: ${e.toString()}'));
    }
  }
  
  Future<void> _onFetchLanguages(
    FetchLanguagesEvent event,
    Emitter<SignupState> emit,
  ) async {
    emit(DataLoadingState());
    
    try {
      final response = await repository.getLanguages();
      
      if (!response.error) {
        languages = response.data ?? [];
        emit(LanguagesLoadedState(languages));
      } else {
        emit(DataLoadingErrorState(response.message));
      }
    } catch (e) {
      emit(DataLoadingErrorState('Failed to load languages: ${e.toString()}'));
    }
  }

  void dispose() {
    // Add any cleanup here
  }
} 