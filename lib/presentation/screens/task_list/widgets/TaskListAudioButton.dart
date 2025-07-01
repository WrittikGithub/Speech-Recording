import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/presentation/widgets/direct_audio_player.dart';

class TaskListAudioButton extends StatelessWidget {
  final String contentId;
  final String? audioPath;
  final String? audioUrl;
  
  const TaskListAudioButton({
    super.key,
    required this.contentId,
    this.audioPath,
    this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Use our direct player without dependencies
    return DirectAudioPlayer(
      contentId: contentId,
      audioPath: audioPath,
      audioUrl: audioUrl,
      size: 48.0,
      backgroundColor: Colors.blue,
      iconColor: Colors.white,
    );
  }
} 