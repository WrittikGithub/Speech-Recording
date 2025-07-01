import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_profile_bloc/fetch_profile_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/dashboard_page/dashboardpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';
import 'package:sdcp_rebuild/presentation/screens/profile_page/profilepage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviews_page/reviewspage.dart';
import 'package:sdcp_rebuild/presentation/screens/tasks_page/taskspage.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sdcp_rebuild/presentation/screens/audio_dashboard/audio_dashboard.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_dashboard_bloc/audio_dashboard_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/decibel_meter_page.dart';

enum DashboardType { task, audio }

class ScreenMainPage extends StatefulWidget {
  final int initialIndex;
  const ScreenMainPage({super.key, this.initialIndex = 0});

  @override
  State<ScreenMainPage> createState() => _ScreenMainPageState();
}

class _ScreenMainPageState extends State<ScreenMainPage> {
  late List<Widget> _pages;
  DashboardType _currentDashboardType = DashboardType.task;
  String _signupApp = '0';
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  @override
  void initState() {
    super.initState();
    _loadPages();
    _initializeProfile();
  }
  
  void _loadPages() {
    // Initialize with base pages, now with 5 pages
    _pages = [
      const ScreenDashboard(),
      const ScreenTaskPage(),
      const DecibelMeterPage(),
      const ScreenReivewPage(),
      const ScreenProfile(),
    ];
    
    print("MainPage: _loadPages() called, initializing base pages");
    
    // Check if we need to replace dashboard with AudioDashboard
    _checkAndUpdateDashboard();
  }
  
  Future<void> _checkAndUpdateDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _signupApp = prefs.getString('SIGNUP_APP') ?? '0';

      print("MainPage: SIGNUP_APP value from SharedPreferences: '$_signupApp'");

      // Check if the value is empty and default to '0'
      if (_signupApp.isEmpty) {
        print("MainPage: Empty SIGNUP_APP value detected, defaulting to '0'");
        _signupApp = '0';
      }

      GlobalState.setAudioDashboardMode(_signupApp == '1');
      print("MainPage: Setting Audio Dashboard Mode: ${_signupApp == '1'}");

      if (!mounted) return; // Check if widget is still mounted

      if (_signupApp == '1') {
        print("MainPage: Using Audio Dashboard mode based on SIGNUP_APP = '1'");
        _currentDashboardType = DashboardType.audio;
      } else {
        print("MainPage: Using Task Dashboard mode based on SIGNUP_APP = '$_signupApp'");
        _currentDashboardType = DashboardType.task;
      }
      _updateDashboardWidget();

    } catch (e) {
      print("Error initializing pages: $e");
      // Fallback if error occurs
       if (mounted) {
          _currentDashboardType = DashboardType.task;
          _updateDashboardWidget();
       }
    }
  }

  void _updateDashboardWidget() {
    Widget dashboardWidget;
    if (_currentDashboardType == DashboardType.audio) {
      dashboardWidget = BlocProvider<AudioDashboardBloc>(
        create: (context) {
          // Create a properly initialized AudioDashboardBloc
          final bloc = AudioDashboardBloc();
          
          // Load both local and server recordings immediately
          bloc.add(LoadRecordingsEvent());
          
          // Add a small delay before loading server recordings to avoid conflicts
          Future.delayed(const Duration(milliseconds: 500), () {
            if (bloc.state is! AudioDashboardError) {
              bloc.add(const LoadServerRecordingsEvent());
            }
          });
          
          return bloc;
        },
        child: AudioDashboard(
          // Pass switchToTaskDashboard callback for users with signup_app=0
          onSwitchToTask: _signupApp == '0' ? switchToTaskDashboard : null,
          scaffoldMessengerKey: _scaffoldMessengerKey,
        ),
      );
      print("Setting _pages[0] to AudioDashboard with fresh AudioDashboardBloc instance.");
    } else {
      dashboardWidget = ScreenDashboard(onSwitchToAudioDashboard: _signupApp == '0' ? switchToAudioDashboard : null);
      print("Setting _pages[0] to ScreenDashboard.");
    }
    
    if (mounted) {
        setState(() {
            if (_pages.isNotEmpty) {
                 _pages[0] = dashboardWidget;
            } else {
                _pages = [
                  dashboardWidget,
                  const ScreenTaskPage(),
                  const DecibelMeterPage(),
                  const ScreenReivewPage(),
                  const ScreenProfile(),
                ];
            }
        });
    }
  }

  void switchToAudioDashboard() {
    if (_currentDashboardType != DashboardType.audio) {
      if (mounted) {
        setState(() {
          _currentDashboardType = DashboardType.audio;
          _updateDashboardWidget();
        });
      }
    }
  }

  void switchToTaskDashboard() {
    if (_signupApp == '0' && _currentDashboardType != DashboardType.task) {
      if (mounted) {
        setState(() {
          _currentDashboardType = DashboardType.task;
          _updateDashboardWidget();
        });
      }
    }
  }

  Future<void> _initializeProfile() async {
    if (!GlobalState().isInitialized) {
      context.read<FetchProfileBloc>().add(FetchProfileInitialEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show navigation loading screen if pages aren't loaded yet
    if (_pages.isEmpty) {
      return Scaffold(
        key: _scaffoldMessengerKey,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get current page from navigation state
    final currentIndex = context.select<BottomNavigationbarBloc, int>(
      (bloc) => bloc.state.currentPageIndex,
    );
    
    // Print debugging info about pages
    print("ScreenMainPage rendering with currentIndex: $currentIndex, pages.length: ${_pages.length}");
    
    // Check if we're in audio dashboard mode
    final isAudioMode = GlobalState.isAudioDashboardMode();
    
    // In audio mode, adjust indices to match the reduced nav bar items
    final safeIndex = isAudioMode
        ? _getSafeAudioIndex(currentIndex)
        : (currentIndex < _pages.length ? currentIndex : 0);
    
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: _pages,
        ),
        bottomNavigationBar: const BottomNavigationWidget(),
      ),
    );
  }

  // Helper method to map navigation indices to page indices in audio mode
  int _getSafeAudioIndex(int navIndex) {
    switch (navIndex) {
      case 0: return 0; // Record -> AudioDashboard (idx 0)
      case 1: return 2; // Decibel -> DecibelMeter (idx 2)
      case 2: return 4; // Profile -> Profile (idx 4)
      default: return 0;
    }
  }
}
