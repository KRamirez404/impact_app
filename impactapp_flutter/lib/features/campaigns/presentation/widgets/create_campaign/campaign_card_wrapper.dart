import 'package:flutter/material.dart';

class CampaignCardWrapper extends StatelessWidget {
  const CampaignCardWrapper({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.contentPadding,
    this.height,
  });

  final String title;
  final String description;
  final Widget child;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.1), width: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500,
                    height: 1.0, color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, height: 1.33, color: Color(0xFF717182),
                  ),
                ),
              ],
            ),
          ),
          if (contentPadding != null)
            Padding(padding: contentPadding!, child: child)
          else
            child,
        ],
      ),
    );
  }
}
