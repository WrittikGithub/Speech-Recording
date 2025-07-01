part of 'fetch_instructions_bloc.dart';

@immutable
sealed class FetchInstructionsState {}

final class FetchInstructionsInitial extends FetchInstructionsState {}

final class FetchInstructionsLoadingState extends FetchInstructionsState {}

final class FetchInstructionsSuccessState extends FetchInstructionsState {
  final List<InstructionDataModel> instructions;

  FetchInstructionsSuccessState({required this.instructions});
}

final class FetchInstructionsErrorState extends FetchInstructionsState {
  final String message;

  FetchInstructionsErrorState({required this.message});
}
