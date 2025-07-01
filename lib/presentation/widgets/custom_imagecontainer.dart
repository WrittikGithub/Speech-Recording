import 'dart:io';
import 'package:flutter/material.dart';

class NetworkFirstImageWidget extends StatelessWidget {
  final String networkUrl;
  final String localPath;
  final BoxFit fit;

  const NetworkFirstImageWidget({
    super.key,
    required this.networkUrl,
    required this.localPath,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      networkUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // If network image fails, try loading from local storage
        if (localPath.isNotEmpty && File(localPath).existsSync()) {
          return Image.file(
            File(localPath),
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              );
            },
          );
        }
        // If both network and local fail, show error icon
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 50,
        );
      },
    );
  }
}