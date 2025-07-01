import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:sdcp_rebuild/data/reviews_model.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';

part 'reviews_assignmentsinterview_event.dart';
part 'reviews_assignmentsinterview_state.dart';

class ReviewsAssignmentsinterviewBloc extends Bloc<
    ReviewsAssignmentsinterviewEvent, ReviewsAssignmentsinterviewState> {
  final Reviewsrepo repository;
  List<ReviewsModel> allReviews = [];
  ReviewsAssignmentsinterviewBloc({required this.repository})
      : super(ReviewsAssignmentsinterviewInitial()) {
    on<ReviewsAssignmentsinterviewEvent>((event, emit) {});
    on<ReviewsAssignmentsInitialFetchingEvent>(reviewsfetching);
    on<ReviewsAssignmentsSearchingEvent>(reviewssearching);
    on<ReviewsAssignmentsFilteringEvent>(reviewsfiltering);
    on<ReviewsAssignmentsRefreshEvent>(refreshreviews);
    on<ReviewsAssignmentsDownloadEvent>(downloadReviews);
    on<ReviewsAssignmentsDownloadSingleEvent>(downloadSingleReview);
  }
  FutureOr<void> reviewsfetching(ReviewsAssignmentsInitialFetchingEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) async {
    emit(ReviewsAssignmentsinterviewLoadingState());
    try {
      final localReviews = await repository.getLocalReviews();
      if (localReviews.isNotEmpty) {
        emit(ReviewsAssignmentsinterviewSuccessState(
            reviewslists: localReviews));
      } else {
         emit(ReviewsAssignmentsinterviewInitial());
      }
     
    } catch (e) {
      emit(ReviwsAssignmentsErrorState(
          message: 'Error loading tasks: ${e.toString()}'));
    }
  }

  // FutureOr<void> reviewsfetching(ReviewsAssignmentsInitialFetchingEvent event,
  //     Emitter<ReviewsAssignmentsinterviewState> emit) async {
  //   emit(ReviewsAssignmentsinterviewLoadingState());
  //   final response = await repository.fetchreviewsAsssignments();
  //   if (!response.error && response.status == 200) {
  //     allReviews = response.data!;
  //     emit(ReviewsAssignmentsinterviewSuccessState(
  //         reviewslists: response.data!));
  //   } else {
  //     emit(ReviwsAssignmentsErrorState(message: response.message));
  //   }
  // }

  FutureOr<void> reviewssearching(ReviewsAssignmentsSearchingEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) async {
    if (event.query.isEmpty) {
      emit(ReviewsAssignmentsinterviewSuccessState(reviewslists: allReviews));
      return;
    }
    final searchrsults = allReviews
        .where((reviews) => reviews.taskTargetId
            .toLowerCase()
            .contains(event.query.toLowerCase()))
        .toList();
    if (searchrsults.isEmpty) {
      emit(ReviewAssignmentsSearchState(searchReviewsList: const []));
    } else {
      emit(ReviewAssignmentsSearchState(searchReviewsList: searchrsults));
    }
  }

  FutureOr<void> reviewsfiltering(ReviewsAssignmentsFilteringEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) {
    List<ReviewsModel> filterdReviews = List.from(allReviews);
    if (event.language != null) {
      filterdReviews = filterdReviews
          .where((reviews) =>
              reviews.languageName.toLowerCase() ==
              event.language!.toLowerCase())
          .toList();
    }
    if (filterdReviews.isEmpty) {
      emit(ReviewsAssignmentsFilterState(filterdReviewsList: const []));
    } else {
      emit(ReviewsAssignmentsFilterState(filterdReviewsList: filterdReviews));
    }
  }

  FutureOr<void> refreshreviews(ReviewsAssignmentsRefreshEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) async{
        try {
          emit(ReviewdownloadingState(progress: 0.0));
          final reviewresponse=await repository.fetchreviewsAsssignments();
          if (!reviewresponse.error && reviewresponse.status==200) {
            await repository.reviewsDatabaseHelper.clearAllReviews();
            await repository.reviewsDatabaseHelper.insertReviews(reviewresponse.data!);
            emit(ReviewdownloadingState(progress: 0.3));
            final totalreviews=reviewresponse.data!.length;
            for (var i = 0; i < totalreviews; i++) {
              emit(ReviewdownloadingState(progress: 0.3 + (0.7 * (i + 1) / totalreviews)));
            }
            final localreviews=await repository.getLocalReviews();
            emit(ReviewsAssignmentsinterviewSuccessState(reviewslists: localreviews));
            
          }
          else{
            emit(ReviwsAssignmentsErrorState(message: reviewresponse.message));
          }
        } catch (e) {
          emit(ReviwsAssignmentsErrorState(message: 'Error refreshing tasks: ${e.toString()}'));
        }
      }
  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }

  FutureOr<void> downloadReviews(ReviewsAssignmentsDownloadEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) async {
    try {
      emit(ReviewdownloadingState(progress: 0.0));
      final response = await repository.fetchreviewsAsssignments();
      if (!response.error && response.status == 200) {
        await repository.reviewsDatabaseHelper.clearAllReviews();
        await repository.reviewsDatabaseHelper.insertReviews(response.data!);
        emit(ReviewdownloadingState(progress: 0.3));
        final totalreviews=response.data!.length;
        for (var i = 0; i < totalreviews; i++) {
          emit(ReviewdownloadingState(
              progress: 0.3 + (0.7 * (i + 1) / totalreviews)));
        }
        final localreviews = await repository.getLocalReviews();
        emit(ReviewsAssignmentsinterviewSuccessState(reviewslists: localreviews));
      } else {
        emit(ReviwsAssignmentsErrorState(message:'Failed to download tasks'));
      }
    } catch (e) {
      emit(ReviwsAssignmentsErrorState(
          message: 'Error downloading tasks: ${e.toString()}'));
    }
  }

  FutureOr<void> downloadSingleReview(ReviewsAssignmentsDownloadSingleEvent event,
      Emitter<ReviewsAssignmentsinterviewState> emit) async {
    try {
      emit(ReviewdownloadingState(progress: 0.0, taskTargetId: event.taskTargetId));
      
      // Skip network check to avoid false negatives
      // Download the specific review task content directly
      final success = await repository.downloadReviewContent(event.taskTargetId);
      
      if (success) {
        // Get the updated reviews list from the database
        final localReviews = await repository.getLocalReviews();
        emit(ReviewsAssignmentsinterviewSuccessState(reviewslists: localReviews));
      } else {
        emit(ReviwsAssignmentsErrorState(
            message: 'Failed to download content. Please try again.',
            taskTargetId: event.taskTargetId));
      }
    } catch (e) {
      emit(ReviwsAssignmentsErrorState(
          message: 'Error: ${e.toString()}',
          taskTargetId: event.taskTargetId));
    }
  }
}
