import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_data/dashboard_data_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_tasklist/dashboard_tasklist_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';

import 'package:sdcp_rebuild/presentation/screens/completed_task_page/completed_taskpage.dart';
import 'package:sdcp_rebuild/presentation/screens/dashboard_page/widgets/database_clearwidget.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';

import 'package:sdcp_rebuild/presentation/screens/notification_page.dart/notification_page.dart';
import 'package:sdcp_rebuild/presentation/screens/report_page/reportpage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewlistpage.dart/reviewlistpage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviews_page/reviewspage.dart';
import 'package:sdcp_rebuild/presentation/screens/tasklistspage.dart/tasklistpage.dart';
import 'package:sdcp_rebuild/presentation/screens/tasks_page/taskspage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';

import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';
import 'package:flutter/services.dart';

class ScreenDashboard extends StatefulWidget {
  final VoidCallback? onSwitchToAudioDashboard;

  const ScreenDashboard({super.key, this.onSwitchToAudioDashboard});

  @override
  State<ScreenDashboard> createState() => _HomePageState();
}

class _HomePageState extends State<ScreenDashboard> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _scrollController.addListener(_updateScrollProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      print('Dashboard initialized with SIGNUP_APP: ${prefs.getString('SIGNUP_APP')}');
    });
  }

  void _fetchDashboardData() {
    context.read<DashboardDataBloc>().add(DashboardDataInitialFetchingEvent());
    context
        .read<DashboardTasklistBloc>()
        .add(DashboardTasklistInitialfetchingEvent());
  }

  void _updateScrollProgress() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollProgress = _scrollController.offset /
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed on the dashboard
        SystemNavigator.pop(); // This will close the app
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextStyles.subheadline(text: 'My Dashboard'),
              ListenableBuilder(
                listenable: GlobalState(),
                builder: (context, _) {
                  return TextStyles.body(
                      text: 'Welcome ${GlobalState().username}');
                },
              )
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                // Navigate to the corresponding page based on the selected value
                switch (value) {
                  case 'Option 1':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationPage()),
                    );
                    break;
                  case 'Option 2':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportPageScreen()),
                    );
                    break;
                  case 'Option 3':
                    // Use a boolean to track dialog status instead of relying on context pop
                    bool isLoading = true;
                    bool success = false;
                    
                    // Show loading dialog
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return WillPopScope(
                            onWillPop: () async => false,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      );
                    }
                    
                    try {
                      // Clear all local data
                      await _clearAllData();
                      success = true;
                    } catch (e) {
                      success = false;
                      // The error will be shown after dialog dismissal
                    } finally {
                      isLoading = false;
                      
                      // Always navigate to login page after this operation completes
                      if (context.mounted) {
                        // First dismiss dialog
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        
                        // Show appropriate message
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All local data cleared successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error clearing local data'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        
                        // Navigate to login page
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
                          (route) => false,
                        );
                      }
                    }
                    break;
                  case 'Option 4':
                    // Show loading indicator during logout
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      // Safely dispose audio resources if possible
                      try {
                        // Try to use the AudioPlayerService to dispose resources
                        AudioPlayerService.dispose();
                      } catch (audioError) {
                        print('Warning: Error disposing audio players: $audioError');
                        // Continue with logout even if audio disposal fails
                      }
                      
                      // DO NOT explicitly close global BLoCs here.
                      // Their lifecycle is managed by the MultiBlocProvider in main.dart.
                      // Closing them here will cause errors if you log back in and try to use them.
                      /*
                      for (final bloc in [
                        context.read<DashboardDataBloc>(),
                        context.read<DashboardTasklistBloc>(),
                        // Add any other BLoCs here that might need to be closed
                      ]) {
                        await bloc.close(); 
                      }
                      */
                      
                      // Clear all shared preferences
                      SharedPreferences preferences = await SharedPreferences.getInstance();
                      await preferences.clear();

                      // Dispatch Google Sign-Out Event
                      // ignore: use_build_context_synchronously
                      if (!mounted) return; 
                      context.read<LoginBloc>().add(GoogleSignOutEvent());
                      
                      // Ensure we're mounted before navigation
                      if (!mounted) return;
                      
                      // Close loading dialog
                      Navigator.of(context).pop();
                      
                      // Use pushAndRemoveUntil to clear the entire navigation stack
                      // This prevents any lingering widget dependencies
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const ScreenLoginPage()),
                        (route) => false,
                      );
                    } catch (e) {
                      print('Error during logout: $e');
                      // Close loading dialog if there's an error
                      if (mounted) Navigator.of(context).pop();
                      
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error during logout: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    break;
                  case 'SwitchToAudio':
                    widget.onSwitchToAudioDashboard?.call();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                // Conditionally add the switch option
                List<PopupMenuEntry<String>> menuItems = [
                  const PopupMenuItem<String>(
                    value: 'Option 1',
                    child: Row(
                      children: [
                        Icon(Icons.notifications, color: Appcolors.kblackColor),
                        SizedBox(width: 8),
                        Text('Notification'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option 2',
                    child: Row(
                      children: [
                        Icon(Icons.report, color: Appcolors.kblackColor),
                        SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option 3',
                    child: Row(
                      children: [
                        Icon(Icons.cleaning_services,
                            color: Appcolors.kblackColor),
                        SizedBox(width: 8),
                        Text('Clear local data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option 4',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Appcolors.kblackColor),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ];

                if (widget.onSwitchToAudioDashboard != null) {
                  menuItems.add(
                    const PopupMenuItem<String>(
                      value: 'SwitchToAudio',
                      child: Row(
                        children: [
                          Icon(Icons.music_note, color: Appcolors.kblackColor), // Example Icon
                          SizedBox(width: 8),
                          Text('My Recordings'),
                        ],
                      ),
                    ),
                  );
                }
                return menuItems;
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
          child: MultiBlocListener(
            listeners: [
              BlocListener<DashboardDataBloc, DashboardDataState>(
                listener: (context, state) {
                  // if (state is DashboardDataErrorState) {
                  //   // Show error message
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text(state.message)),
                  //   );
                  // }
                },
              ),
              BlocListener<DashboardTasklistBloc, DashboardTasklistState>(
                listener: (context, state) {
                  // if (state is DashboardTasklistErrorState) {
                  //   // Show error message
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text(state.message)),
                  //   );
                  // }
                },
              ),
            ],
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchDashboardData();
              },
              child: BlocBuilder<DashboardDataBloc, DashboardDataState>(
                builder: (context, dashboardState) {
                  if (dashboardState is DashboardDataInitial) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Appcolors.klightBgColor, size: 40),
                    );
                  }

                  if (dashboardState is DashboardDataLoadingState) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Appcolors.klightBgColor, size: 40),
                    );
                  }

                  if (dashboardState is DashboardDataErrorState) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${dashboardState.message}'),
                          ElevatedButton(
                            onPressed: _fetchDashboardData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (dashboardState is DashboardDataSuccessState) {
                    return ListView(
                      children: [
                        ResponsiveSizedBox.height20,
                        GridView(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.7,
                          ),
                          children: [
                            // First Container
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.lightBlue[100]!, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextStyles.headline(
                                        text: dashboardState
                                            .dashboardDatas.totalTasks
                                            .toString(),
                                        color: Appcolors.kprimaryColor,
                                      ),
                                      ResponsiveSizedBox.height5,
                                      const ResponsiveText(
                                        'Tasks', // Replace with your API data key
                                        weight: FontWeight.bold,
                                        sizeFactor: .85,
                                        color: Appcolors.kprimaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Second Container
                            GestureDetector(
                              onTap: () {
                                context.read<BottomNavigationbarBloc>().add(
                                      NavigateToPageEvent(
                                          pageIndex: 1), // Set to Tasks page
                                    );

                                // Navigate to Completed Tasks
                                navigatePush(context,
                                    const ScreenCompletedTaskPage()); // or ScreenCompletedTaskPage() with bottom navigation
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.lightBlue[100]!, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextStyles.headline(
                                        text: dashboardState
                                            .dashboardDatas.totalCompletedTask
                                            .toString(),
                                        color: Appcolors.kprimaryColor,
                                      ),
                                      ResponsiveSizedBox.height5,
                                      const ResponsiveText(
                                        'Completed',
                                        weight: FontWeight.bold,
                                        sizeFactor: .85,
                                        color: Appcolors.kprimaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () {
                                context.read<BottomNavigationbarBloc>().add(
                                      NavigateToPageEvent(pageIndex: 1),
                                    );

                                navigatePush(
                                    context,
                                    const ScreenTaskPage(
                                      showBackButton: true,
                                    ));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.lightBlue[100]!, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextStyles.headline(
                                        text: dashboardState
                                            .dashboardDatas.totalPendingRecordTask
                                            .toString(),
                                        color: Appcolors.kprimaryColor,
                                      ),
                                      ResponsiveSizedBox.height5,
                                      const ResponsiveText(
                                        'Pending Record Task',
                                        weight: FontWeight.bold,
                                        sizeFactor: .85,
                                        color: Appcolors.kprimaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Fourth Container
                            GestureDetector(
                              onTap: () {
                                context.read<BottomNavigationbarBloc>().add(
                                      NavigateToPageEvent(pageIndex: 0),
                                    );

                                navigatePush(
                                    context,
                                    const ScreenReivewPage(
                                      showBackButton: true,
                                    ));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.lightBlue[100]!, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextStyles.headline(
                                        text: dashboardState
                                            .dashboardDatas.totalPendingReviewTask
                                            .toString(),
                                        color: Appcolors.kprimaryColor,
                                      ),
                                      ResponsiveSizedBox.height5,
                                      const ResponsiveText(
                                        'Pending Review Task',
                                        weight: FontWeight.bold,
                                        sizeFactor: .85,
                                        color: Appcolors.kprimaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'My Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Horizontal scrolling containers
                        SizedBox(
                          height: ResponsiveUtils.hp(24),
                          child: BlocBuilder<DashboardTasklistBloc,
                              DashboardTasklistState>(
                            builder: (context, state) {
                              if (state is DashboardTasklistLoadingState) {
                                return Center(
                                  child: LoadingAnimationWidget.staggeredDotsWave(
                                      color: Appcolors.klightBgColor,
                                      size: 40),
                                );
                              }
                              if (state is DashboardTasklistSuccessState) {
                                return ListView.builder(
                                  controller: _scrollController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.tasklist.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        state.tasklist[index].status ==
                                                'IN-PROGRESS'
                                            ? navigatePush(
                                                context,
                                                ScreenTaskListPage(
                                                    taskTargetID: state
                                                        .tasklist[index]
                                                        .taskTargetId,
                                                    taskTitle: state
                                                        .tasklist[index]
                                                        .taskTitle))
                                            : navigatePush(
                                                context,
                                                ScreenReviewListPage(
                                                    taskTargetID: state
                                                        .tasklist[index]
                                                        .taskTargetId,
                                                    taskTitle: state
                                                        .tasklist[index]
                                                        .taskTitle));
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 16),
                                        width: ResponsiveUtils.wp(38),
                                        decoration: BoxDecoration(
                                          color: Appcolors.klightBgColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  ResponsiveSizedBox.height30,
                                                  Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.task,
                                                            size: 50),
                                                        ResponsiveSizedBox
                                                            .height10,
                                                        TextStyles.body(
                                                            text: 'Task Progress',
                                                            weight:
                                                                FontWeight.bold),
                                                        ResponsiveSizedBox
                                                            .height10,
                                                        LinearProgressIndicator(
                                                          value: state
                                                                  .tasklist[index]
                                                                  .pendingPercent /
                                                              100,
                                                          minHeight: 6,
                                                          color: Appcolors.kprimaryColor,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                        ),
                                                        ResponsiveSizedBox
                                                            .height10,
                                                        const ResponsiveText(
                                                          'Project Name',
                                                          sizeFactor: .9,
                                                          weight: FontWeight.bold,
                                                        ),
                                                        ResponsiveSizedBox
                                                            .height5,
                                                        TextStyles.caption(
                                                            text: state
                                                                .tasklist[index]
                                                                .project),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // "In Progress" Label in the top-right corner
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: const BoxDecoration(
                                                  color: Appcolors.klightBgColor,
                                                  borderRadius: BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(10),
                                                      bottomLeft:
                                                          Radius.circular(5)),
                                                ),
                                                child: ResponsiveText(
                                                  state.tasklist[index].status,
                                                  sizeFactor: .7,
                                                  color: Appcolors.kprimaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        ResponsiveSizedBox.height20,
                        LinearProgressIndicator(
                          minHeight: 6,
                          value: _scrollProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Appcolors.kprimaryColor),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alarm,
                              size: 40,
                              color: Appcolors.klightBgColor,
                            ),
                            ResponsiveSizedBox.height10,
                            TextStyles.subheadline(text: 'Hurry up!'),
                            ResponsiveSizedBox.height5,
                            Text(
                              'Please complete the remaining\n${dashboardState.dashboardDatas.totalPendingTask} pending tasks',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return const Center(
                    child: Text('Something went wrong. Please try again.'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    await LocalDataCleaner().clearAllLocalData(); // Clear the data
    
    // Navigate to the login page after clearing data
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
      (route) => false,
    );
  }
}
