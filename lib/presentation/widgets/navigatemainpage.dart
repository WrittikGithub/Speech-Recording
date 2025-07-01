
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';

void navigateToMainPage(BuildContext context, int pageIndex) {
  // Navigate to ScreenMainPage
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const ScreenMainPage()),
  );

  // After navigation, update the BLoC to show the desired page
  BlocProvider.of<BottomNavigationbarBloc>(context).add(
    NavigateToPageEvent(pageIndex: pageIndex),
  );
}