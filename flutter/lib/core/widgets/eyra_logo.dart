import 'package:flutter/material.dart';

/// Renders the official Eyra brand asset with an optional subtle cyan
/// ambient glow behind it. The source image itself is never modified,
/// cropped, or redrawn.
class EyraLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const EyraLogo({super.key, this.size = 120, this.withGlow = false});

  @override
  Widget build(BuildContext context) {
    final image = Semantics(
      label: 'Eyra logo',
      image: true,
      child: Image.asset(
        'assets/branding/eyra_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );

    if (!withGlow) return image;

    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size * 1.7,
      height: size * 1.7,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            cs.secondary.withValues(alpha: 0.3),
            cs.secondary.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: image,
    );
  }
}
