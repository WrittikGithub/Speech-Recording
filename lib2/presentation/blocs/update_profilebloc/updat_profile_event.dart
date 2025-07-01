part of 'updat_profile_bloc.dart';

@immutable
sealed class UpdatProfileEvent {}

final class UpdateProfileButtonClickingEvent extends UpdatProfileEvent {
  final String? userfullName;
  final String? userEmail;
  final String? username;

  UpdateProfileButtonClickingEvent({required this.userfullName, required this.userEmail, required this.username});


}
