part of 'notification_bloc.dart';

@immutable
sealed class NotificationState {}

final class NotificationInitial extends NotificationState {}

final class NotificationFetchingLoadingState extends NotificationState {}

final class NotificationFetchingSuccessState extends NotificationState {
  final List<NotificationMOdel> notifications;

  NotificationFetchingSuccessState({required this.notifications});
}

final class NotificationFetchingErrorState extends NotificationState {
  final String message;

  NotificationFetchingErrorState({required this.message});
}
