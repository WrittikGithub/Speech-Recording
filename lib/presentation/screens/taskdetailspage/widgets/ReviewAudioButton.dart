import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/widgets/simple_audio_player.dart';

class ReviewAudioButton extends StatelessWidget {
  final String contentId;
  final String? audioPath;
  final String? audioUrl;
  final double size;
  
  const ReviewAudioButton({
    super.key,
    required this.contentId,
    this.audioPath,
    this.audioUrl,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    // If we have a local audio path, use it directly with SimpleAudioPlayer
    if (audioPath != null && audioPath!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: SimpleAudioPlayer(
          audioPath: audioPath!,
          size: size,
          backgroundColor: Appcolors.kpurpleColor,
          iconColor: Colors.white,
        ),
      );
    }
    
    // If no audio path but we have a URL, show disabled state
    // The URL handling should be done elsewhere before showing this button
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
} 