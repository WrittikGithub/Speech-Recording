import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/core/colors.dart';

part 'toggle_password_state.dart';

class TogglepasswordCubit extends Cubit<bool> {
  TogglepasswordCubit() : super(true);

  void togglePassword() {
    emit(!state);
  }
}