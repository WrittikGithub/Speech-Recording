import 'dart:math' as math;
import 'package:flutter/material.dart';

class AudioWaveform extends StatelessWidget {
  final List<double> samples;
  final double height;
  final Color color;
  final bool isRecording;

  const AudioWaveform({
    Key? key,
    required this.samples,
    this.height = 100,
    this.color = Colors.red,
    this.isRecording = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: WaveformPainter(
          samples: samples,
          color: color,
          isRecording: isRecording,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color color;
  final bool isRecording;
  final Paint _paint;

  WaveformPainter({
    required this.samples,
    required this.color,
    required this.isRecording,
  }) : _paint = Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final path = Path();
    final middle = size.height / 2;
    final width = size.width;
    final sampleWidth = width / samples.length;

    path.moveTo(0, middle);

    for (var i = 0; i < samples.length; i++) {
      final x = i * sampleWidth;
      final y = middle + (samples[i] * middle);
      path.lineTo(x, y);
    }

    // Add pulsing effect when recording
    if (isRecording) {
      _paint.color = color.withOpacity(0.6 + math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) * 0.4);
    }

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      samples != oldDelegate.samples ||
      color != oldDelegate.color ||
      isRecording != oldDelegate.isRecording;
} 