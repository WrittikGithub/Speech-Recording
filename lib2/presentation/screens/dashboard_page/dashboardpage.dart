import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_data/dashboard_data_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/dashboard_tasklist/dashboard_tasklist_bloc.dart';

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

class ScreenDashboard extends StatefulWidget {
  const ScreenDashboard({super.key});

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
    return Scaffold(
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
                    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Clear all local data
      await LocalDataCleaner().clearAllLocalData();

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local data cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing local data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
                  break;
                case 'Option 4':
                  SharedPreferences preferences =
                      await SharedPreferences.getInstance();
                  await preferences
                      .clear(); // Clears everything in SharedPreferences

                  // Navigate to the Sign-In screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
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
                        color: Appcolors.kpurpledoublelightColor, size: 40),
                  );
                }

                if (dashboardState is DashboardDataLoadingState) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Appcolors.kpurpledoublelightColor, size: 40),
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
                                color: Appcolors.kpurplelightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextStyles.headline(
                                      text: dashboardState
                                          .dashboardDatas.totalTasks
                                          .toString(),
                                      color: Appcolors.kwhiteColor,
                                    ),
                                    ResponsiveSizedBox.height5,
                                    const ResponsiveText(
                                      'Tasks', // Replace with your API data key
                                      weight: FontWeight.bold,
                                      sizeFactor: .85,
                                      color: Appcolors.kwhiteColor,
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
                                color: Appcolors.kpurplelightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextStyles.headline(
                                      text: dashboardState
                                          .dashboardDatas.totalCompletedTask
                                          .toString(),
                                      color: Appcolors.kwhiteColor,
                                    ),
                                    ResponsiveSizedBox.height5,
                                    const ResponsiveText(
                                      'Completed',
                                      weight: FontWeight.bold,
                                      sizeFactor: .85,
                                      color: Appcolors.kwhiteColor,
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
                                color: Appcolors.kpurplelightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextStyles.headline(
                                      text: dashboardState
                                          .dashboardDatas.totalPendingRecordTask
                                          .toString(),
                                      color: Appcolors.kwhiteColor,
                                    ),
                                    ResponsiveSizedBox.height5,
                                    const ResponsiveText(
                                      'Pending Record Task',
                                      weight: FontWeight.bold,
                                      sizeFactor: .85,
                                      color: Appcolors.kwhiteColor,
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
                                    NavigateToPageEvent(pageIndex: 2),
                                  );

                              navigatePush(
                                  context,
                                  const ScreenReivewPage(
                                    showBackButton: true,
                                  ));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Appcolors.kpurplelightColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextStyles.headline(
                                      text: dashboardState
                                          .dashboardDatas.totalPendingReviewTask
                                          .toString(),
                                      color: Appcolors.kwhiteColor,
                                    ),
                                    ResponsiveSizedBox.height5,
                                    const ResponsiveText(
                                      'Pending Review Task',
                                      weight: FontWeight.bold,
                                      sizeFactor: .85,
                                      color: Appcolors.kwhiteColor,
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
                                    color: Appcolors.kpurpledoublelightColor,
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
                                        color: Appcolors.kskybluecolor,
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
                                                        color: Colors.blue,
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
                                                color: Appcolors.korangeColor,
                                                borderRadius: BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10),
                                                    bottomLeft:
                                                        Radius.circular(5)),
                                              ),
                                              child: ResponsiveText(
                                                state.tasklist[index].status,
                                                sizeFactor: .7,
                                                color: Appcolors.kwhiteColor,
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
                            Appcolors.kpurplelightColor),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.alarm,
                            size: 40,
                            color: Appcolors.korangeColor,
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
    );
  }
}
