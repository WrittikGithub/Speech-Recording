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
                      );}),
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
