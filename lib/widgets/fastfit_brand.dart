import 'package:flutter/material.dart';
import 'fastfit_motion.dart';

/// Brand mark composed of standard vector primitives, not emoji or third-party art.
class FastFitLogo extends StatelessWidget {
  final bool onDark;
  final double size;
  final bool showName;
  const FastFitLogo({super.key, this.onDark = false, this.size = 42,
    this.showName = true});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: onDark ? Colors.white : FastFitStyle.red,
          borderRadius: BorderRadius.circular(size * 0.29)),
        child: Icon(Icons.favorite_rounded, size: size * 0.48,
          color: onDark ? FastFitStyle.red : Colors.white),
      ),
      if (showName) ...[
        SizedBox(width: size * 0.23),
        Text('FastFit', style: TextStyle(
          color: onDark ? Colors.white : FastFitStyle.ink,
          fontWeight: FontWeight.w900, letterSpacing: -0.9,
          fontSize: size * 0.55)),
      ],
    ]);
}
