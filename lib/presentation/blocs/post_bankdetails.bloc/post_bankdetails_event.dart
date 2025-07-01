part of 'post_bankdetails_bloc.dart';

@immutable
sealed class PostBankdetailsEvent {}

final class PostBankdetailsButtonClickEvent extends PostBankdetailsEvent {
  final PostbankDetailsModel bankdetails;

  PostBankdetailsButtonClickEvent({required this.bankdetails});
}
