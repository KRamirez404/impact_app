import 'package:flutter/material.dart';

class TabsHeader extends StatelessWidget {
  const TabsHeader({
    super.key,
    required this.tabController,
    required this.commentsCount,
  });

  final TabController tabController;
  final int commentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0A0A0A),
        unselectedLabelColor: const Color(0xFF0A0A0A),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        labelPadding: EdgeInsets.zero,
        tabs: [
          const Tab(text: 'Info'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16),
                const SizedBox(width: 6),
                Text(commentsCount.toString()),
              ],
            ),
          ),
          const Tab(text: 'Avances'),
          const Tab(text: 'Docs'),
        ],
      ),
    );
  }
}
