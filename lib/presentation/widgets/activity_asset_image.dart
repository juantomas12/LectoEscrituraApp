import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ActivityAssetImage extends StatelessWidget {
  const ActivityAssetImage({
    super.key,
    required this.assetPath,
    this.semanticsLabel,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final String? semanticsLabel;
  final BoxFit fit;

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  int? _cacheDimension(double logicalPixels, double devicePixelRatio) {
    if (!logicalPixels.isFinite || logicalPixels <= 0) {
      return null;
    }
    final raw = (logicalPixels * devicePixelRatio).round();
    return raw.clamp(48, 2048);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.asset(
        assetPath,
        semanticsLabel: semanticsLabel,
        fit: fit,
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final fallbackSize = math.min(
          MediaQuery.sizeOf(context).shortestSide,
          640.0,
        );
        final cacheWidth =
            _cacheDimension(constraints.maxWidth, dpr) ??
            _cacheDimension(fallbackSize, dpr);
        final cacheHeight =
            _cacheDimension(constraints.maxHeight, dpr) ??
            _cacheDimension(fallbackSize, dpr);

        return Image.asset(
          assetPath,
          fit: fit,
          semanticLabel: semanticsLabel,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: const Text(
                'IMAGEN NO DISPONIBLE',
                textAlign: TextAlign.center,
              ),
            );
          },
        );
      },
    );
  }
}
