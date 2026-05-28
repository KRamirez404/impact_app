import 'package:flutter/material.dart';
import 'quick_action_button.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.likesCount,
    required this.isLiked,
    required this.isLikeLoading,
    required this.commentsCount,
    required this.onLike,
    required this.onComments,
    required this.onRate,
  });

  final int likesCount;
  final bool isLiked;
  final bool isLikeLoading;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        QuickActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: likesCount.toString(),
          onTap: onLike,
          isDisabled: isLikeLoading,
          iconColor: isLiked ? const Color(0xFFE53935) : const Color(0xFF0A0A0A),
          labelColor: isLiked ? const Color(0xFFE53935) : const Color(0xFF0A0A0A),
        ),
        const SizedBox(width: 8),
        QuickActionButton(
          icon: Icons.chat_bubble_outline,
          label: commentsCount.toString(),
          onTap: onComments,
        ),
        const SizedBox(width: 8),
        QuickActionButton(
          icon: Icons.star_border,
          label: 'Calificar',
          onTap: onRate,
        ),
        const SizedBox(width: 8),
        QuickActionButton(
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: () {},
        ),
      ],
    );
  }
}
