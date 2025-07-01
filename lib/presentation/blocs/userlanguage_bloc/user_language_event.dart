part of 'user_language_bloc.dart';

@immutable
sealed class UserLanguageEvent {}
final class UserLanguageFetchingEvent extends UserLanguageEvent{}