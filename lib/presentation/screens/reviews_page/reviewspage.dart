// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:sdcp_rebuild/core/colors.dart';
// import 'package:sdcp_rebuild/core/constants.dart';
// import 'package:sdcp_rebuild/core/responsive_utils.dart';
// import 'package:sdcp_rebuild/domain/databases/review_content_database_helper.dart';
// import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';
// import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/reviewassignments_bloc/reviews_assignmentsinterview_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
// import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
// import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
// import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';
// import 'package:sdcp_rebuild/presentation/screens/reviewlistpage.dart/reviewlistpage.dart';
// import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/filtered_review_bottomsheet.dart';
// import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/review_taskcard.dart';
// import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/review_audio_button.dart';

// import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
// import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
// import 'package:sdcp_rebuild/presentation/screens/home_routing.dart';
// import '../../widgets/simple_audio_player.dart';

// class ScreenReivewPage extends StatefulWidget {
//   final bool showBackButton;
//   const ScreenReivewPage({super.key, this.showBackButton = false});

//   @override
//   State<ScreenReivewPage> createState() => _ScreenTaskPageState();
// }

// class _ScreenTaskPageState extends State<ScreenReivewPage> {
//   bool _isSearching = false;
//   final TextEditingController _searchController = TextEditingController();
//   @override
//   void initState() {
//     super.initState();
//     _checkLocalData();
//     context.read<UserLanguageBloc>().add(UserLanguageFetchingEvent());
//   }

//   void _checkLocalData() {
//     // Ensure we request the latest data from the local database
//     Future.microtask(() {
//       if (mounted) {
//     context
//         .read<ReviewsAssignmentsinterviewBloc>()
//         .add(ReviewsAssignmentsInitialFetchingEvent());
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) {
//         if (!didPop) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const HomeRoutingScreen()),
//             (route) => false,
//           );
//           context.read<BottomNavigationbarBloc>().add(
//             NavigateToPageEvent(pageIndex: 0),
//           );
//         }
//       },
//       child: BlocBuilder<ReviewsAssignmentsinterviewBloc, ReviewsAssignmentsinterviewState>(
//         builder: (context, state) {
//           return AbsorbPointer(
//             absorbing: state is ReviewdownloadingState && state.taskTargetId == null,
//             child: BlocProvider(
//               create: (context) => ReviewContentBloc(repository: Reviewsrepo()),
//               child: Scaffold(
//                 appBar: AppBar(
//                   leading: widget.showBackButton
//                       ? IconButton(
//                           icon: const Icon(
//                             CupertinoIcons.chevron_back,
//                             size: 32,
//                           ),
//                           onPressed: () {
//                             Navigator.of(context).pushAndRemoveUntil(
//                               MaterialPageRoute(
//                                   builder: (context) => const ScreenMainPage()),
//                               (route) => false,
//                             );
                
//                             // Ensure dashboard (index 0) is highlighted
//                             context.read<BottomNavigationbarBloc>().add(
//                                   NavigateToPageEvent(pageIndex: 0),
//                                 );
//                           },
//                         )
//                       : null,
//                   elevation: 0,
//                   title: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       TextStyles.subheadline(text: 'My Reviews'),
//                       ListenableBuilder(
//                         listenable: GlobalState(),
//                         builder: (context, _) {
//                           return TextStyles.body(
//                               text: 'Hello! ${GlobalState().username}');
//                         },
//                       )
//                     ],
//                   ),
//                   actions: [
//                     IconButton(
//                       icon: const Icon(Icons.tune, color: Colors.black),
//                       onPressed: () {
//                         showModalBottomSheet(
//                             context: context,
//                             shape: const RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.vertical(
//                                     top: Radius.circular(16))),
//                             builder: (context) => const FilterReviewBottomSheet());
//                       },
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.search, color: Colors.black),
//                       onPressed: () {
//                         setState(() {
//                           _isSearching = true;
//                         });
//                       },
//                     ),
//                   ],
//                   bottom: _isSearching
//                       ? PreferredSize(
//                           preferredSize: const Size.fromHeight(60),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             child: TextField(
//                               controller: _searchController,
//                               autofocus: true,
//                               decoration: InputDecoration(
//                                 hintText: 'Search by Task ID...',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.grey[100],
//                                 suffixIcon: IconButton(
//                                   onPressed: () {
//                                     setState(() {
//                                       _isSearching = false;
//                                       _searchController.clear();
//                                     });
//                                     context
//                                         .read<ReviewsAssignmentsinterviewBloc>()
//                                         .add(
//                                             ReviewsAssignmentsInitialFetchingEvent());
//                                   },
//                                   icon: const Icon(Icons.clear),
//                                 ),
//                               ),
//                               onChanged: (query) {
//                                 context.read<ReviewsAssignmentsinterviewBloc>().add(
//                                     ReviewsAssignmentsSearchingEvent(query: query));
//                               },
//                             ),
//                           ),
//                         )
//                       : null,
//                 ),
//                 body: Stack(
//                   children: [
//                       if (state is ReviewsAssignmentsinterviewLoadingState) 
//                        Center(
//                           child: LoadingAnimationWidget.staggeredDotsWave(
//                               color: Appcolors.kpurpledoublelightColor, size: 40),
//                         )
//                          else if (state is ReviewdownloadingState && state.taskTargetId == null) 
//                         Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             CircularProgressIndicator(
//                               value: state.progress,
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                                 'Downloading... ${(state.progress * 100).toInt()}%'),
//                           ],
//                         ),
//                       )
//                        else if (state is ReviewsAssignmentsinterviewInitial)
//                       Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text('Download tasks to begin'),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: () {
//                                 context.read<ReviewsAssignmentsinterviewBloc>().add(ReviewsAssignmentsDownloadEvent());
//                               },
//                               child: const Text('Download Reviews'),
//                             ),
//                           ],
//                         ),
//                       )
//                        else if (state is ReviewsAssignmentsinterviewSuccessState ||
//                           state is ReviewAssignmentsSearchState ||
//                           state is ReviewsAssignmentsFilterState) 
//                           Builder(builder: (context) {
//                         final reviews =
//                             state is ReviewsAssignmentsinterviewSuccessState
//                                 ? state.reviewslists
//                                 : state is ReviewAssignmentsSearchState
//                                     ? (state)
//                                         .searchReviewsList
//                                     : (state as ReviewsAssignmentsFilterState)
//                                         .filterdReviewsList;
//                         if (reviews.isEmpty) {
//                           return const Center(
//                             child: Text('No Review tasks found'),
//                           );
//                         }
              
//                         return RefreshIndicator(
//                           onRefresh: ()async{
//                             context.read<ReviewsAssignmentsinterviewBloc>().add(ReviewsAssignmentsRefreshEvent());
//                           },
//                           child: ListView.builder(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: ResponsiveUtils.wp(4),
//                               vertical: ResponsiveUtils.wp(4),
//                             ),
//                             itemCount: reviews.length,
//                             itemBuilder: (context, index) {
//                               final review = reviews[index];
//                               return GestureDetector(
//                                 onTap: () {
//                                   navigatePush(
//                                       context,
//                                       ScreenReviewListPage(
//                                           taskTargetID: review.taskTargetId,
//                                           taskTitle: review.taskTitle));
//                                 },
//                                   child: Container(
//                                     margin: const EdgeInsets.symmetric(vertical: 10),
//                                     padding: const EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(10),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.grey.withOpacity(0.2),
//                                           spreadRadius: 1,
//                                           blurRadius: 3,
//                                           offset: const Offset(0, 1),
//                                         ),
//                                       ],
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             Text(
//                                               truncateWithEllipsis(review.project, 25),
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 16,
//                                               ),
//                                             ),
//                                             Row(
//                                               children: [
//                                                 BlocConsumer<ReviewsAssignmentsinterviewBloc, ReviewsAssignmentsinterviewState>(
//                                                   listener: (context, downloadState) {
//                                                     if (downloadState is ReviwsAssignmentsErrorState && 
//                                                         downloadState.taskTargetId == review.taskTargetId) {
//                                                       try {
//                                                         // Check if the context is still valid before showing snackbar
//                                                         if (context.mounted) {
//                                                           // Show snackbar for quick feedback
//                                                           ScaffoldMessenger.of(context).showSnackBar(
//                                                             SnackBar(
//                                                               content: Text(
//                                                                 downloadState.message.contains('network') 
//                                                                   ? 'No internet connection available. Please connect to WiFi or mobile data and try again.'
//                                                                   : 'Download failed: ${downloadState.message}',
//                                                                 style: const TextStyle(
//                                                                   color: Colors.white,
//                                                                   fontWeight: FontWeight.w500,
//                                                                 ),
//                                                               ),
//                                                               backgroundColor: Colors.red.shade700,
//                                                               duration: const Duration(seconds: 5),
//                                                               action: SnackBarAction(
//                                                                 label: 'Retry',
//                                                                 textColor: Colors.white,
//                                                                 onPressed: () {
//                                                                   if (context.mounted) {
//                                                                     context.read<ReviewsAssignmentsinterviewBloc>().add(
//                                                                       ReviewsAssignmentsDownloadSingleEvent(taskTargetId: review.taskTargetId)
//                                                                     );
//                                                                   }
//                                                                 },
//                                                               ),
//                                                             ),
//                                                           );
                                                          
//                                                           // If it's a network error, also show a more detailed dialog
//                                                           if (downloadState.message.contains('network')) {
//                                                             _showNetworkErrorDialog(context, review.taskTargetId);
//                                                           }
//                                                         }
//                                                       } catch (e) {
//                                                         debugPrint('Error showing snackbar: $e');
//                                                       }
//                                                     } else if (downloadState is ReviewsAssignmentsinterviewSuccessState) {
//                                                       // Check if this update was for our review
//                                                       final updatedReview = downloadState.reviewslists.firstWhere(
//                                                         (r) => r.taskTargetId == review.taskTargetId,
//                                                         orElse: () => review
//                                                       );
                                                      
//                                                       if (updatedReview.targetContentPath != null && 
//                                                           updatedReview.targetContentPath!.isNotEmpty &&
//                                                           context.mounted) {
//                                                         ScaffoldMessenger.of(context).showSnackBar(
//                                                           SnackBar(
//                                                             content: const Text('Audio downloaded successfully!'),
//                                                             backgroundColor: Colors.green,
//                                                             duration: const Duration(seconds: 2),
//                                                           ),
//                                                         );
//                                                       }
//                                                     }
//                                                   },
//                                                   builder: (context, downloadState) {
//                                                     final isLoading = downloadState is ReviewdownloadingState &&
//                                                         downloadState.taskTargetId == review.taskTargetId;
                                                    
//                                                     if (isLoading) {
//                                                       return SizedBox(
//                                                         width: ResponsiveUtils.wp(6),
//                                                         height: ResponsiveUtils.wp(6),
//                                                         child: LoadingAnimationWidget.inkDrop(
//                                                           color: Appcolors.kpurpleColor,
//                                                           size: ResponsiveUtils.wp(5)
//                                                         ),
//                                                       );
//                                                     }
                                                    
//                                                     return GestureDetector(
//                                                       onTap: () {
//                                                         context.read<ReviewsAssignmentsinterviewBloc>().add(
//                                                           ReviewsAssignmentsDownloadSingleEvent(taskTargetId: review.taskTargetId)
//                                                         );
//                                                       },
//                                                       child: Icon(
//                                                         review.targetContentPath != null && review.targetContentPath!.isNotEmpty 
//                                                           ? Icons.refresh : Icons.download,
//                                                         color: Appcolors.kpurpleColor,
//                                                         size: ResponsiveUtils.wp(6),
//                                                       ),
//                                                     );
//                                                   },
//                                                 ),
//                                                 const SizedBox(width: 12),
//                                                 if (review.targetContentPath != null && review.targetContentPath!.isNotEmpty)
//                                                   FutureBuilder<String?>(
//                                                     future: _getFirstContentId(review.taskTargetId),
//                                                     builder: (context, contentIdSnapshot) {
//                                                       if (contentIdSnapshot.connectionState == ConnectionState.waiting) {
//                                                         return SizedBox(
//                                                           width: ResponsiveUtils.wp(9),
//                                                           height: ResponsiveUtils.wp(9),
//                                                           child: Center(
//                                                             child: SizedBox(
//                                                               width: ResponsiveUtils.wp(5),
//                                                               height: ResponsiveUtils.wp(5),
//                                                               child: CircularProgressIndicator(
//                                                                 color: Appcolors.kpurpleColor,
//                                                                 strokeWidth: 2,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         );
//                                                       }
                                                      
//                                                       if (!contentIdSnapshot.hasData || contentIdSnapshot.data == null) {
//                                                         return SimpleAudioPlayer(
//                                                           audioPath: review.targetContentPath!,
//                                                           size: ResponsiveUtils.wp(9),
//                                                           backgroundColor: Appcolors.kpurpleColor,
//                                                           iconColor: Colors.white,
//                                                         );
//                                                       }
                                                      
//                                                       return ReviewAudioButton(
//                                         taskCode: review.taskTargetId,
//                                                           contentId: contentIdSnapshot.data!,
//                                                           size: ResponsiveUtils.wp(9),
//                                                           backgroundColor: Appcolors.kpurpleColor,
//                                                           iconColor: Colors.white,
//                                                         );
//                                                     }
//                                                   ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         'Task Code: ${review.taskTargetId}',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         'Task Status: ${review.status}',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                               ),
//                             );
//                           },
//                         ),
//                         );
//                       }),
//                       if (state is ReviewdownloadingState && state.taskTargetId == null)
                   
//                     Container(
//                       color: Colors.black.withOpacity(0.3),
//                       child: const Center(
//                         child: Text(
//                           'Please wait while downloading...',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//               ]),
//               bottomNavigationBar: widget.showBackButton 
//                   ? BlocProvider(
//                       create: (context) => BottomNavigationbarBloc(),
//                       child: const BottomNavigationWidget(),
//                     ) 
//                   : null,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Helper function to truncate text with ellipsis
// String truncateWithEllipsis(String text, int maxLength) {
//   if (text.length <= maxLength) {
//     return text;
//   }
//   return text.substring(0, maxLength) + '...';
// }

// // Function to get the first contentId for a task
// Future<String?> _getFirstContentId(String taskTargetId) async {
//   final dbHelper = ReviewContentDatabaseHelper();
//   try {
//     debugPrint('Fetching contentId for taskTargetId: $taskTargetId');
//     final contents = await dbHelper.getContentsByTargetTaskTargetId(taskTargetId);
    
//     if (contents.isNotEmpty) {
//       final contentId = contents.first.contentId;
//       debugPrint('Found contentId: $contentId for taskTargetId: $taskTargetId');
//       return contentId;
//     }
    
//     debugPrint('No content found for taskTargetId: $taskTargetId');
//     return null;
//   } catch (e) {
//     debugPrint('Error getting contentId for $taskTargetId: $e');
//     return null;
//   }
// }

// // Function to show network error dialog
// void _showNetworkErrorDialog(BuildContext context, String taskId) {
//   // Check if context is still valid
//   if (!context.mounted) return;
  
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => AlertDialog(
//       title: Row(
//         children: [
//           const Icon(Icons.signal_wifi_off, color: Colors.red),
//           const SizedBox(width: 10),
//           const Text('No Internet Connection'),
//         ],
//       ),
//       content: const Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Unable to download audio content because there is no internet connection available.',
//             style: TextStyle(fontSize: 16),
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Please check:',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text('• Your WiFi connection is active'),
//           Text('• Your mobile data is turned on'),
//           Text('• You are not in airplane mode'),
//           SizedBox(height: 16),
//           Text(
//             'Once connected, try downloading again.',
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'You can still use the app with locally saved content.',
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Continue Offline'),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.pop(context);
//             if (context.mounted) {
//               context.read<ReviewsAssignmentsinterviewBloc>().add(
//                 ReviewsAssignmentsDownloadSingleEvent(taskTargetId: taskId)
//               );
//             }
//           },
//           child: const Text('Retry'),
//         ),
//       ],
//     ),
//   );
// }
// above code by AI 

// written by me 
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/bottom_navigation/bottom_navigationbar_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/reviewassignments_bloc/reviews_assignmentsinterview_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/widgets/customnavbar.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewlistpage.dart/reviewlistpage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/filtered_review_bottomsheet.dart';
import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/review_taskcard.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';


import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

class ScreenReivewPage extends StatefulWidget {
  final bool showBackButton;
  const ScreenReivewPage({super.key, this.showBackButton = false});

  @override
  State<ScreenReivewPage> createState() => _ScreenTaskPageState();
}

class _ScreenTaskPageState extends State<ScreenReivewPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    //_fetchReviewsdata();
    _checkLocalData();
    context.read<UserLanguageBloc>().add(UserLanguageFetchingEvent());
  }

  // void _fetchReviewsdata() {
  //   context
  //       .read<ReviewsAssignmentsinterviewBloc>()
  //       .add(ReviewsAssignmentsInitialFetchingEvent());
  // }
  void _checkLocalData() {
    context
        .read<ReviewsAssignmentsinterviewBloc>()
        .add(ReviewsAssignmentsInitialFetchingEvent());
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
      child: BlocBuilder<ReviewsAssignmentsinterviewBloc, ReviewsAssignmentsinterviewState>(
        builder: (context, state) {
          return AbsorbPointer(
            absorbing: state is ReviewdownloadingState,
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
            
                          // Ensure dashboard (index 0) is highlighted
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
                    TextStyles.subheadline(text: 'My Reviews'),
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
                          builder: (context) => const FilterReviewBottomSheet());
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
                                      .read<ReviewsAssignmentsinterviewBloc>()
                                      .add(
                                          ReviewsAssignmentsInitialFetchingEvent());
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ),
                            onChanged: (query) {
                              context.read<ReviewsAssignmentsinterviewBloc>().add(
                                  ReviewsAssignmentsSearchingEvent(query: query));
                            },
                          ),
                        ),
                      )
                    : null,
              ),
              body: Stack(
                children: [
                    if (state is ReviewsAssignmentsinterviewLoadingState) 
                     Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Appcolors.kpurpledoublelightColor, size: 40),
                      )
                     else if (state is ReviewdownloadingState) 
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
                     else if (state is ReviewsAssignmentsinterviewInitial)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Download tasks to begin'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ReviewsAssignmentsinterviewBloc>().add(ReviewsAssignmentsDownloadEvent());
                            },
                            child: const Text('Download Reviews'),
                          ),
                        ],
                      ),
                    )
                     else if (state is ReviewsAssignmentsinterviewSuccessState ||
                        state is ReviewAssignmentsSearchState ||
                        state is ReviewsAssignmentsFilterState) 
                        Builder(builder: (context) {
                      final reviews =
                          state is ReviewsAssignmentsinterviewSuccessState
                              ? state.reviewslists
                              : state is ReviewAssignmentsSearchState
                                  ? (state)
                                      .searchReviewsList
                                  : (state as ReviewsAssignmentsFilterState)
                                      .filterdReviewsList;
                      if (reviews.isEmpty) {
                        return const Center(
                          child: Text('No Review tasks found'),
                        );
                      }
            
                      return RefreshIndicator(
                        onRefresh: ()async{
                          context.read<ReviewsAssignmentsinterviewBloc>().add(ReviewsAssignmentsRefreshEvent());
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.wp(4),
                            vertical: ResponsiveUtils.wp(4),
                          ),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return GestureDetector(
                              onTap: () {
                                context.read<ReviewContentBloc>().add(SelectTileEvent(index));
                                navigatePush(
                                    context,
                                    ScreenReviewListPage(
                                        taskTargetID: review.taskTargetId,
                                        taskTitle: review.taskTitle));
                              },
                              child: ReviewTaskcard(
                                index: index,
                                title: review.project,
                                taskCode: review.taskTargetId,
                                taskPrefix: review.taskPrefix,
                                taskStatus: review.status,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    if(state is ReviewdownloadingState)
                   
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Text(
                          'Please wait while downloading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
              ]),
              bottomNavigationBar:
                  widget.showBackButton ? const BottomNavigationWidget() : null,
            ),
          );
        },
      ),
    );
  }
}
