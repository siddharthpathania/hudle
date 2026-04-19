import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.avatarUrls,
    super.key,
    this.size = 28,
    this.max = 3,
  });

  final List<String?> avatarUrls;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final visible = avatarUrls.take(max).toList();
    final overflow = avatarUrls.length - max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.asMap().entries.map(
              (e) => Transform.translate(
                offset: Offset(e.key * -8.0, 0),
                child: _Avatar(url: e.value, size: size),
              ),
            ),
        if (overflow > 0)
          Transform.translate(
            offset: Offset(visible.length * -8.0, 0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.inkElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inkBorder),
              ),
              child: Center(
                child: Text(
                  '+$overflow',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.inkBase, width: 2),
        color: AppColors.inkMuted,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(Icons.person, size: 16),
            )
          : const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
    );
  }
}
