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
import 'package:sdcp_rebuild/presentation/widgets/syncprogress_class.dart';

class ScreenMainPage extends StatefulWidget {
  const ScreenMainPage({super.key});

  @override
  State<ScreenMainPage> createState() => _ScreenMainPageState();
}

class _ScreenMainPageState extends State<ScreenMainPage> {
  final List<Widget> _pages = [
    const ScreenDashboard(),
    const ScreenTaskPage(),
    const ScreenReivewPage(),
    const ScreenProfile(),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    if (!GlobalState().isInitialized) {
      context.read<FetchProfileBloc>().add(FetchProfileInitialEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationbarBloc, BottomNavigationbarState>(
      builder: (context, state) {
        return Scaffold(
          //body: _pages[state.currentPageIndex],
           body: Stack(
            children: [
              _pages[state.currentPageIndex],
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: StreamBuilder<SyncProgressState>(
                  stream: SyncProgress().syncProgressStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.isSyncing) {
                      return const SizedBox.shrink();
                    }

                    final progress = snapshot.data!;
                    return Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                              value: progress.progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Syncing ${progress.completedItems}/${progress.totalItems}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavigationWidget(),
        );
      },
    );
  }
}
