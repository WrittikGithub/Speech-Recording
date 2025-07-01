part of 'image_picker_bloc.dart';

@immutable
sealed class ImagePickerEvent {}

final class AadharImagePickingEvent extends ImagePickerEvent {
  final File aadharimage;

  AadharImagePickingEvent({required this.aadharimage});
}

final class BankproofImagePickingEvent extends ImagePickerEvent {
  final File bankproofimage;

  BankproofImagePickingEvent({required this.bankproofimage});
}
