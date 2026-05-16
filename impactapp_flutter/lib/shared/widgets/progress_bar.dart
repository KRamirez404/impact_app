import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalized = (progress / 100).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: normalized),
        const SizedBox(height: 2),
        Text('${progress.toStringAsFixed(1)}%'),
      ],
    );
  }
}

