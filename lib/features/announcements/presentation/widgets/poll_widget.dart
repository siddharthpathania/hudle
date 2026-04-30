import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../domain/announcement_model.dart';

class PollWidget extends StatelessWidget {
  const PollWidget({
    required this.poll,
    required this.onVote,
    super.key,
  });

  final Poll poll;
  final void Function(String optionId) onVote;

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasVoted;
    final showResults = hasVoted || poll.isClosed;
    final total = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface(context),
        borderRadius: BorderRadius.circular(UI.radiusMd),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_outlined,
                  size: 16, color: AppColors.amberGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  poll.question,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (poll.isClosed)
                Text(
                  'Closed',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.mutedText(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final o in poll.options) ...[
            _OptionTile(
              option: o,
              total: total,
              showResults: showResults,
              isMine: poll.myVoteOptionId == o.id,
              disabled: poll.isClosed,
              onTap: () => onVote(o.id),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
          Text(
            total == 0
                ? 'No votes yet'
                : '$total vote${total == 1 ? '' : 's'}'
                    '${hasVoted ? ' · You voted' : ''}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.total,
    required this.showResults,
    required this.isMine,
    required this.disabled,
    required this.onTap,
  });

  final PollOption option;
  final int total;
  final bool showResults;
  final bool isMine;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : option.votes / total;
    final tappable = !disabled && !showResults;

    return InkWell(
      onTap: tappable ? onTap : null,
      borderRadius: BorderRadius.circular(UI.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UI.radiusSm),
          border: Border.all(
            color:
                isMine ? AppColors.emberOrange : AppColors.border(context),
            width: isMine ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (showResults)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppColors.emberOrange.withValues(alpha: 0.18)
                          : AppColors.hudleTeal.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(UI.radiusSm - 1),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                if (tappable) ...[
                  Icon(
                    isMine
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: isMine
                        ? AppColors.emberOrange
                        : AppColors.mutedText(context),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option.text,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight:
                          isMine ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (showResults) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(pct * 100).round()}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.mutedText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
