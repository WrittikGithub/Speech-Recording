part of 'post_bankdetails_bloc.dart';

@immutable
sealed class PostBankdetailsState {}

final class PostBankdetailsInitial extends PostBankdetailsState {}

final class PostBankdetailsLoadingState extends PostBankdetailsState {}

final class PostBankdetailsSuccessState extends PostBankdetailsState {
  final String message;

  PostBankdetailsSuccessState({required this.message});
}

final class PostBankdetailsErrorState extends PostBankdetailsState {
  final String message;

  PostBankdetailsErrorState({required this.message});
}
