// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:sdcp_rebuild/core/colors.dart';
// import 'package:sdcp_rebuild/core/constants.dart';
// import 'package:sdcp_rebuild/core/responsive_utils.dart';
// import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/task_bloc/task_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
// import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
// import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';
// import 'package:sdcp_rebuild/presentation/screens/tasklistspage.dart/tasklistpage.dart';
// import 'package:sdcp_rebuild/presentation/screens/tasks_page/widgets/filtterbottomsheet.dart';
// import 'package:sdcp_rebuild/presentation/screens/tasks_page/widgets/taskcard.dart';
// import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
// import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

// class ScreenTaskPage extends StatefulWidget {
//   final bool showBackButton;
//   const ScreenTaskPage({super.key, this.showBackButton = false});

//   @override
//   State<ScreenTaskPage> createState() => _ScreenTaskPageState();
// }

// class _ScreenTaskPageState extends State<ScreenTaskPage> {
//   bool _isSearching = false;
//   final TextEditingController _searchController = TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     _fetchtaskdata();
//     context.read<UserLanguageBloc>().add(UserLanguageFetchingEvent());
//   }

//   void _fetchtaskdata() {
//     context.read<TaskBloc>().add(TaskFetchingInitialEvent());
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//         canPop: false,
//       onPopInvokedWithResult: (didPop,result) {
//         if (!didPop) {
//           // When back button is pressed, navigate to main page and set dashboard index
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const ScreenMainPage()),
//             (route) => false,
//           );

//           // Ensure dashboard (index 0) is highlighted
//           context.read<BottomNavigationbarBloc>().add(
//                 NavigateToPageEvent(pageIndex: 0),
//               );
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           leading: widget.showBackButton
//               ? IconButton(
//                   icon: const Icon(
//                     CupertinoIcons.chevron_back,
//                     size: 32,
//                   ),
//                   onPressed: () {
//                          Navigator.of(context).pushAndRemoveUntil(
//                   MaterialPageRoute(builder: (context) => const ScreenMainPage()),
//                   (route) => false,
//                 );

//                 // Ensure dashboard (index 0) is highlighted
//                 context.read<BottomNavigationbarBloc>().add(
//                       NavigateToPageEvent(pageIndex: 0),
//                     );
//                   },
//                 )
//               : null,
//           elevation: 0,
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextStyles.subheadline(text: 'My Tasks'),
//               ListenableBuilder(
//                 listenable: GlobalState(),
//                 builder: (context, _) {
//                   return TextStyles.body(
//                       text: 'Hellow! ${GlobalState().username}');
//                 },
//               )
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.tune, color: Colors.black),
//               onPressed: () {
//                 showModalBottomSheet(
//                     context: context,
//                     shape: const RoundedRectangleBorder(
//                         borderRadius:
//                             BorderRadius.vertical(top: Radius.circular(16))),
//                     builder: (context) => const FilterBottomSheet());
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.search, color: Colors.black),
//               onPressed: () {
//                 setState(() {
//                   _isSearching = true;
//                 });
//               },
//             ),
//           ],
//           bottom: _isSearching
//               ? PreferredSize(
//                   preferredSize: const Size.fromHeight(60),
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: TextField(
//                       controller: _searchController,
//                       autofocus: true,
//                       decoration: InputDecoration(
//                         hintText: 'Search by Task ID...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[100],
//                         suffixIcon: IconButton(
//                           onPressed: () {
//                             setState(() {
//                               _isSearching = false;
//                               _searchController.clear();
//                             });
//                             context
//                                 .read<TaskBloc>()
//                                 .add(TaskFetchingInitialEvent());
//                           },
//                           icon: const Icon(Icons.clear),
//                         ),
//                       ),
//                       onChanged: (query) {
//                         context
//                             .read<TaskBloc>()
//                             .add(TaskSerachEvent(query: query));
//                       },
//                     ),
//                   ),
//                 )
//               : null,
//         ),
//         body: BlocBuilder<TaskBloc, TaskState>(
//           builder: (context, state) {
//             if (state is TaskFetchingLoadingState) {
//               return Center(
//                 child: LoadingAnimationWidget.staggeredDotsWave(
//                     color: Appcolors.kpurpledoublelightColor, size: 40),
//               );
//             } else if (state is TaskFetchingErrorState) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(state.message),
//                     ElevatedButton(
//                       onPressed: () => _fetchtaskdata,
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               );
//             } else if (state is TaskFetchingSuccessState ||
//                 state is TasksearchState ||
//                 state is TaskFilteredState) {
//               final tasks = state is TaskFetchingSuccessState
//                   ? state.tasks
//                   : state is TasksearchState
//                       ? (state).searchResult
//                       : (state as TaskFilteredState).filteredTasks;
//               if (tasks.isEmpty) {
//                 return const Center(
//                   child: Text('No tasks found'),
//                 );
//               }

//               return RefreshIndicator(
//                 onRefresh: () async {
//                   context.read<TaskBloc>().add(TaskRefreshEvent());
//                 },
//                 child: ListView.builder(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: ResponsiveUtils.wp(4),
//                     vertical: ResponsiveUtils.wp(4),
//                   ),
//                   itemCount: tasks.length,
//                   itemBuilder: (context, index) {
//                     final task = tasks[index];
//                     return GestureDetector(
//                       onTap: () {
//                         navigatePush(
//                             context,
//                             ScreenTaskListPage(
//                               taskTargetID: task.taskTargetId,
//                               taskTitle: task.taskTitle,
//                             ));
//                       },
//                       child: TaskCard(
//                         index: index,
//                         title: task.project,
//                         taskCode: task.taskTargetId,
//                         taskPrefix: task.taskPrefix,
//                         taskStatus: task.status,
//                       ),
//                     );
//                   },
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           },
//         ),
//         bottomNavigationBar: widget.showBackButton?BottomNavigationWidget():null,
//       ),
//     );
//   }
// }
////////////////////////////////////////
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/task_bloc/task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';
import 'package:sdcp_rebuild/presentation/screens/tasklistspage.dart/tasklistpage.dart';
import 'package:sdcp_rebuild/presentation/screens/tasks_page/widgets/filtterbottomsheet.dart';
import 'package:sdcp_rebuild/presentation/screens/tasks_page/widgets/taskcard.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

class ScreenTaskPage extends StatefulWidget {
  final bool showBackButton;
  const ScreenTaskPage({super.key, this.showBackButton = false});

  @override
  State<ScreenTaskPage> createState() => _ScreenTaskPageState();
}

class _ScreenTaskPageState extends State<ScreenTaskPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _checkLocalData();
    context.read<UserLanguageBloc>().add(UserLanguageFetchingEvent());
  }

  void _checkLocalData() {
    context.read<TaskBloc>().add(TaskFetchingInitialEvent());
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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ScreenMainPage()),
            (route) => false,
          );

          context.read<BottomNavigationbarBloc>().add(
                NavigateToPageEvent(pageIndex: 0),
              );
        }
      },
      child: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          return AbsorbPointer(
            absorbing: state is TaskDownloadingState,
            child: Scaffold(
              appBar: AppBar(
                leading: widget.showBackButton
                    ? IconButton(
                        icon: const Icon(
                          CupertinoIcons.chevron_back,
                          size: 32,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const ScreenMainPage()),
                            (route) => false,
                          );
            
                          context.read<BottomNavigationbarBloc>().add(
                                NavigateToPageEvent(pageIndex: 0),
                              );
                        },
                      )
                    : null,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextStyles.subheadline(text: 'My Tasks'),
                    ListenableBuilder(
                      listenable: GlobalState(),
                      builder: (context, _) {
                        return TextStyles.body(
                            text: 'Hello! ${GlobalState().username}');
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
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16))),
                          builder: (context) => const FilterBottomSheet());
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                      .read<TaskBloc>()
                                      .add(TaskFetchingInitialEvent());
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ),
                            onChanged: (query) {
                              context
                                  .read<TaskBloc>()
                                  .add(TaskSerachEvent(query: query));
                            },
                          ),
                        ),
                      )
                    : null,
              ),
              body: Stack(
                children: [
                  if (state is TaskFetchingLoadingState)
                    Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Appcolors.kpurpledoublelightColor,
                        size: 40,
                      ),
                    )
                  else if (state is TaskDownloadingState)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: state.progress,
                          ),
                          const SizedBox(height: 16),
                          Text(
                              'Downloading... ${(state.progress * 100).toInt()}%'),
                        ],
                      ),
                    )
                  else if (state is TaskInitial)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Download tasks to begin'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<TaskBloc>().add(TaskDownloadEvent());
                            },
                            child: const Text('Download Tasks'),
                          ),
                        ],
                      ),
                    )
                  else if (state is TaskFetchingSuccessState ||
                      state is TasksearchState ||
                      state is TaskFilteredState)
                    Builder(
                      builder: (context) {
                        final tasks = state is TaskFetchingSuccessState
                            ? state.tasks
                            : state is TasksearchState
                                ? state.searchResult
                                : (state as TaskFilteredState).filteredTasks;
                        
                        if (tasks.isEmpty) {
                          return const Center(
                            child: Text('No tasks found'),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            context.read<TaskBloc>().add(TaskRefreshEvent());
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.wp(4),
                              vertical: ResponsiveUtils.wp(4),
                            ),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return GestureDetector(
                                onTap: () {
                                  navigatePush(
                                    context,
                                    ScreenTaskListPage(
                                      taskTargetID: task.taskTargetId,
                                      taskTitle: task.taskTitle,
                                    ),
                                  );
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
                          ),
                        );
                      },
                    ),
                  if (state is TaskDownloadingState)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Text(
                          'Please wait while downloading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: widget.showBackButton 
                  ? BlocProvider(
                      create: (context) => BottomNavigationbarBloc(),
                      child: const BottomNavigationWidget(),
                    ) 
                  : null,
            ),
          );
        },
      ),
    );
  }
}
