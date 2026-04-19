import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../domain/announcement_model.dart';

class ReactionsBar extends StatelessWidget {
  const ReactionsBar({
    required this.reactions,
    required this.onReact,
    super.key,
  });

  final List<AnnouncementReaction> reactions;
  final void Function(String emoji) onReact;

  static const _defaults = ['👍', '❤️', '🎉', '🔥', '👀'];

  @override
  Widget build(BuildContext context) {
    final existing = {for (final r in reactions) r.emoji: r};
    final showAdd =
        _defaults.any((e) => !existing.containsKey(e)) || reactions.isEmpty;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in reactions) _Chip(reaction: r, onTap: () => onReact(r.emoji)),
        if (showAdd)
          PopupMenuButton<String>(
            tooltip: 'React',
            onSelected: onReact,
            itemBuilder: (_) => [
              for (final e in _defaults)
                PopupMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UI.radiusFull),
                border: Border.all(color: AppColors.inkBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_reaction_outlined, size: 14),
                  SizedBox(width: 4),
                  Text('React', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.reaction, required this.onTap});
  final AnnouncementReaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UI.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: reaction.mine
              ? AppColors.emberOrange.withValues(alpha: 0.15)
              : AppColors.inkMuted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(UI.radiusFull),
          border: Border.all(
            color: reaction.mine
                ? AppColors.emberOrange
                : AppColors.inkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '${reaction.count}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: reaction.mine
                    ? AppColors.emberOrange
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
