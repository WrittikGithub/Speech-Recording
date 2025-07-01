import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';

import 'package:sdcp_rebuild/presentation/blocs/review_comment_bloc/review_comment_bloc.dart';

import 'package:sdcp_rebuild/presentation/blocs/save_review_comment/save_reviewcomment_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

import 'package:timeago/timeago.dart' as timeago;



class ReviewCommentpage extends StatefulWidget {
  final String taskTargetId;
  final String contentId;
  const ReviewCommentpage(
      {super.key, required this.taskTargetId, required this.contentId});

  @override
  State<ReviewCommentpage> createState() => _ReviewCommentpageState();
}

class _ReviewCommentpageState extends State<ReviewCommentpage> {
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  void _fetchComments() {
    context.read<ReviewCommentBloc>().add(FetchReviewCommentInitialEvent(
        contentId: widget.contentId, taskTargetId: widget.taskTargetId));
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 243, 238, 238),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 184, 178, 178),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ReviewCommentBloc,ReviewCommentState>(
                    builder: (context, state) {
                      if (state is FetchReviewCommmentLoadingState) {
                        return Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Appcolors.kpurplelightColor, size: 30),
                        );
                      }
                      if (state is FetchReviewCommentErrorState) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.message),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchComments,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state is FetchReviewCommentSuccessState) {
                        return state.comments.isEmpty? const Center(child:Text('NO Comments'),) :ListView.builder(
                          controller: scrollController,
                          itemCount: state.comments.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final comment = state.comments[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Appcolors.kskybluecolor,
                                    radius: 20,
                                    child: Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.commentBy,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(comment.comment),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextStyles.caption(
                                                text: timeago.format(
                                                    DateTime.parse(
                                                        comment.createdDate)))
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        color: Colors.white,
        child: SafeArea(
          child: BlocConsumer<SaveReviewcommentBloc, SaveReviewcommentState>(
            listener: (context, state) {
              if (state is SaveReviewCommentSuccessState) {
                commentController.clear();
                _fetchComments();

                CustomSnackBar.show(
                    context: context,
                    title: 'Success',
                    message: 'Comment added successfully',
                    contentType: ContentType.success);
              } else if (state is SaveReviewCommentErrorState) {
                CustomSnackBar.show(
                    context: context,
                    title: 'Error',
                    message: state.message,
                    contentType: ContentType.failure);
              }
            },
            builder: (context, state) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          fillColor: Colors.grey[100],
                          filled: true,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    state is SaveReviewCommentLoadingState
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send,
                                color: Appcolors.kpurpleColor),
                            onPressed: () {
                              String comment = commentController.text.trim();
                              if (comment.isEmpty) {
                                CustomSnackBar.show(
                                    context: context,
                                    title: 'Error!!',
                                    message: 'Please Enter Comment',
                                    contentType: ContentType.failure);
                                return;
                              }
                              context.read<SaveReviewcommentBloc>().add(
                                  SaveReviewCommentButtonClickingEvent(
                                      taskTargetId: widget.taskTargetId,
                                      contentId: widget.contentId,
                                      comment: comment));
                            },
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
