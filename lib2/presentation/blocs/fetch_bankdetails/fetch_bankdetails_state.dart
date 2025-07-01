part of 'fetch_bankdetails_bloc.dart';

@immutable
sealed class FetchBankdetailsState {}

final class FetchBankdetailsInitial extends FetchBankdetailsState {}

final class FetchBankdetailsLoadingState extends FetchBankdetailsState {}

final class FetchBankdetailsSuccessState extends FetchBankdetailsState {
  final BankdetailsModel bankdetails;

  FetchBankdetailsSuccessState({required this.bankdetails});
}

final class FetchBankdetailsErrorState extends FetchBankdetailsState {
  final String message;

  FetchBankdetailsErrorState({required this.message});
}
