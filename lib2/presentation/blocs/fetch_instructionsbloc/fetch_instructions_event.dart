part of 'fetch_instructions_bloc.dart';

@immutable
sealed class FetchInstructionsEvent {}

final class FetchingInstructionsInitialEvent extends FetchInstructionsEvent {
  final String contentId;

  FetchingInstructionsInitialEvent({required this.contentId});
}
