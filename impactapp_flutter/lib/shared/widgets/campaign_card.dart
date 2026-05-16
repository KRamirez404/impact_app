import 'package:flutter/material.dart';
import 'progress_bar.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String description;
  final double progress;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            ProgressBar(progress: progress),
            const SizedBox(height: 4),
            Text('Estado: $status'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

