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

    return Image.asset(
      assetPath,
      fit: fit,
      semanticLabel: semanticsLabel,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: const Text(
            'IMAGEN NO DISPONIBLE',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
