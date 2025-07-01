part of 'updat_profile_bloc.dart';

@immutable
sealed class UpdatProfileState {}

final class UpdatProfileInitial extends UpdatProfileState {}

final class UpdateProfileLoadingState extends UpdatProfileState {}

final class UpdateProfileSuccessState extends UpdatProfileState {
  final String message;

  UpdateProfileSuccessState({required this.message});
}

final class UpdateProfileErrorState extends UpdatProfileState {
  final String message;

  UpdateProfileErrorState({required this.message});
}
