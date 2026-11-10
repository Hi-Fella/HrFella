import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

const _kLogoUrl =
    'https://backoffice.hi-fella.com/assets/hi-fella-logo-short-BOsqZg2t.png';

/// The HRFella mark loaded from the CDN.
///
/// Kept as one widget so the next asset change is still one edit.
class HorillaMark extends StatelessWidget {
  const HorillaMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _kLogoUrl,
      width: size,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(width: size, height: size),
      errorWidget: (context, url, error) =>
          SizedBox(width: size, height: size),
    );
  }
}

/// Mark plus the "HRFella" wordmark, as on the sign-in screen.
class HorillaLockup extends StatelessWidget {
  const HorillaLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'HRFella',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HorillaMark(size: 52),
          const SizedBox(width: AppSpace.x12),
          // Fixed size: the wordmark is artwork, not reading text, and at 2x
          // it ran 72pt off the screen. The name is in the label above.
          MediaQuery.withNoTextScaling(
            child: Text(
              'HRFella',
              style: AppText.appBarTitle.copyWith(
                fontSize: 26,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 40pt white tile holding the mark, used at the top of Home.
class HorillaMarkTile extends StatelessWidget {
  const HorillaMarkTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.floating,
      ),
      alignment: Alignment.center,
      child: const HorillaMark(size: 28),
    );
  }
}
