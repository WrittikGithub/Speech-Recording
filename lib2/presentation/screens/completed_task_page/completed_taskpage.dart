import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/completed_task_bloc/completed_task_bloc.dart';

import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/completed_task_page/widgets/filter_bottomsheet.dart';
import 'package:sdcp_rebuild/presentation/screens/completed_tasklist_page.dart/completed_tasklistpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';



import 'package:sdcp_rebuild/presentation/screens/tasks_page/widgets/taskcard.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';


class ScreenCompletedTaskPage extends StatefulWidget {
  const ScreenCompletedTaskPage({super.key});

  @override
  State<ScreenCompletedTaskPage> createState() => _ScreenTaskPageState();
}

class _ScreenTaskPageState extends State<ScreenCompletedTaskPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchtaskdata();
    context.read<UserLanguageBloc>().add(UserLanguageFetchingEvent());
  }

  void _fetchtaskdata() {
    context.read<CompletedTaskBloc>().add(CompletedTaskInitialFetchingEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
     canPop: false,
      onPopInvokedWithResult: (didPop,result) {
        if (!didPop) {
          // When back button is pressed, navigate to main page and set dashboard index
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ScreenMainPage()),
            (route) => false,
          );
          
          // Ensure dashboard (index 0) is highlighted
          context.read<BottomNavigationbarBloc>().add(
                NavigateToPageEvent(pageIndex: 0),
              );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
           leading: IconButton(
            icon: const Icon(
              CupertinoIcons.chevron_back,
              size: 32,
            ),
            onPressed: () {
               Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const ScreenMainPage()),
                  (route) => false,
                );
                
                // Ensure dashboard (index 0) is highlighted
                context.read<BottomNavigationbarBloc>().add(
                      NavigateToPageEvent(pageIndex: 0),
                    );
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextStyles.subheadline(text: 'My Completed Tasks'),
                   ListenableBuilder(
        listenable: GlobalState(),
        builder: (context, _) {
      return      TextStyles.body(text: 'Hellow ${GlobalState().username}');
        },
      )
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (context) => const FilterBottomSheetCompletedTask());
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          ],
          bottom: _isSearching
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by Task ID...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                            });
                            context
                                .read<CompletedTaskBloc>()
                                .add(CompletedTaskInitialFetchingEvent());
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onChanged: (query) {
                        context
                            .read<CompletedTaskBloc>()
                            .add(CompletedTaskSearchEvent(query: query));
                      },
                    ),
                  ),
                )
              : null,
        ),
        body: BlocBuilder<CompletedTaskBloc, CompletedTaskState>(
          builder: (context, state) {
            if (state is CompletedTaskLoadingState) {
              return Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Appcolors.kpurplelightColor, size: 40),
              );
            } else if (state is CompletedTaskErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    ElevatedButton(
                      onPressed: () => _fetchtaskdata,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is CompletedTskSuccessState ||
                state is CompletedTaskSearchState||
                state is CompletedTaskFilterState) {
              final tasks = state is CompletedTskSuccessState
                  ? state.completedtasks
                  : state is CompletedTaskSearchState
                      ? (state).searchresults
                      : (state as CompletedTaskFilterState).filteredtasks;
              if (tasks.isEmpty) {
                return const Center(
                  child: Text('No tasks found'),
                );
              }
      
              return ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.wp(4),
                  vertical: ResponsiveUtils.wp(4),
                ),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return GestureDetector(
                    onTap: () {
                      navigatePush(context, CompletedTaskListPage(taskTargetID: task.taskTargetId,taskTitle: task.taskTitle,));
                    },
                    child: TaskCard(
                      index: index,
                      title: task.project,
                      taskCode: task.taskTargetId,
                      taskPrefix: task.taskPrefix,
                      taskStatus: task.status,
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
       bottomNavigationBar: const BottomNavigationWidget(),
      ),
    );
  }
}
