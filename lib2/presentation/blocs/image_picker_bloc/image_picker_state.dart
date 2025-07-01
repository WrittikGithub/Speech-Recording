part of 'image_picker_bloc.dart';

@immutable
sealed class ImagePickerState {}

final class ImagePickerInitial extends ImagePickerState {}



final class AadharImagePickerSuccessState extends ImagePickerState {
  final File aadharimage;

  AadharImagePickerSuccessState({required this.aadharimage});

 
}

final class BankproofeImageSuccessState extends ImagePickerState {
  final File bankproofimage;

  BankproofeImageSuccessState({required this.bankproofimage});

 

 
}
