import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';

import 'package:meta/meta.dart';

part 'image_picker_event.dart';
part 'image_picker_state.dart';

class ImagePickerBloc extends Bloc<ImagePickerEvent, ImagePickerState> {
  ImagePickerBloc() : super(ImagePickerInitial()) {
    on<ImagePickerEvent>((event, emit) {});
    on<AadharImagePickingEvent>(aadharimagepicking);
    on<BankproofImagePickingEvent>(bankproofimagepicking);
  }

  FutureOr<void> aadharimagepicking(
      AadharImagePickingEvent event, Emitter<ImagePickerState> emit) {
    emit(AadharImagePickerSuccessState(aadharimage: event.aadharimage));
  }

  FutureOr<void> bankproofimagepicking(
      BankproofImagePickingEvent event, Emitter<ImagePickerState> emit) {
    emit(BankproofeImageSuccessState(bankproofimage: event.bankproofimage));
  }
}
