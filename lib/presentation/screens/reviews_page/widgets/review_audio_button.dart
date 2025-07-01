import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';

class ReviewAudioButton extends StatelessWidget {
  final String taskCode;
  final String contentId;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  
  const ReviewAudioButton({
    super.key,
    required this.taskCode,
    required this.contentId,
    this.size = 48.0,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewContentBloc, ReviewContentState>(
      builder: (context, state) {
        // Check if audio is currently playing
        final isPlaying = state is ReviewContentPlayingAudioState &&
            state.contentTaskTargetId == taskCode &&
            state.contentId == contentId;
            
        // Check if there was an error playing this specific audio
        final hasError = state is ReviewContentAudioErrorState &&
            state.contentTaskTargetId == taskCode &&
            state.contentId == contentId;
            
        // If there's an error, show error icon
        if (hasError) {
          return GestureDetector(
            onTap: () {
              // Allow retry
              context.read<ReviewContentBloc>().add(
                ReviewContentPlayAudioEvent(
                  taskTargetId: taskCode,
                  contentId: contentId
                )
              );
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.refresh,
                  color: iconColor,
                  size: size * 0.6,
                ),
              ),
            ),
          );
        }
        
        // If it's downloading or playing, show loading animation
        if (isPlaying) {
          return GestureDetector(
            onTap: () {
              // Optionally add stop functionality
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.stop,
                  color: iconColor,
                  size: size * 0.6,
                ),
              ),
            ),
          );
        }
        
        // Default play button
        return GestureDetector(
          onTap: () {
            context.read<ReviewContentBloc>().add(
              ReviewContentPlayAudioEvent(
                taskTargetId: taskCode,
                contentId: contentId
              )
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.play_arrow,
                color: iconColor,
                size: size * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }
} 