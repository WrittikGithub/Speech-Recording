import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/completed_task_page/completed_taskpage.dart';

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  bool _isAudioDashboard = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkAppMode();
  }

  Future<void> _checkAppMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final signupApp = prefs.getString('SIGNUP_APP') ?? '0';
      
      if (mounted) {
        setState(() {
          _isAudioDashboard = signupApp == '1';
          _isLoaded = true;
          print("Audio dashboard mode: $_isAudioDashboard");
        });
      }
    } catch (e) {
      print("Error checking app mode: $e");
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until we've checked the app mode
    if (!_isLoaded) {
      return BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Loading...'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Loading...'),
        ],
        currentIndex: 0,
        onTap: (_) {}, // No-op during loading
      );
    }

    return BlocBuilder<BottomNavigationbarBloc, BottomNavigationbarState>(
      builder: (context, state) {
        if (_isAudioDashboard) {
          // Audio Dashboard navigation (only 3 items - Recording, Decibel, Profile)
          return BottomNavigationBar(
            currentIndex: state.currentPageIndex,
            onTap: (index) {
              final bloc = context.read<BottomNavigationbarBloc>();
              print("Audio Navigation bar tap: index=$index, dispatching to bloc");
              bloc.add(NavigateToPageEvent(pageIndex: index));
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Appcolors.kpurpleColor,
            selectedItemColor: Appcolors.kwhiteColor,
            unselectedItemColor: Appcolors.kpurplelightColor,
            selectedIconTheme: const IconThemeData(color: Appcolors.kwhiteColor),
            unselectedIconTheme: const IconThemeData(color: Appcolors.kpurplelightColor),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                label: 'Record',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.volume_up),
                label: 'Decibel',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        } else {
          // Regular Dashboard navigation (5 items including Decibel)
          return BottomNavigationBar(
            currentIndex: state.currentPageIndex,
            onTap: (index) {
              final bloc = context.read<BottomNavigationbarBloc>();
              print("Standard Navigation bar tap: index=$index, dispatching to bloc");
              bloc.add(NavigateToPageEvent(pageIndex: index));
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Appcolors.kpurpleColor,
            selectedItemColor: Appcolors.kwhiteColor,
            unselectedItemColor: Appcolors.kpurplelightColor,
            selectedIconTheme: const IconThemeData(color: Appcolors.kwhiteColor),
            unselectedIconTheme: const IconThemeData(color: Appcolors.kpurplelightColor),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.volume_up),
                label: 'Decibel',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review),
                label: 'Reviews',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        }
      },
    );
  }
}

class CompletedTaskWrapper extends StatelessWidget {
  const CompletedTaskWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenCompletedTaskPage();
  }
}